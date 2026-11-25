-- ============================================================================
-- SKRIP SQL DATABASE, TRIGGER, STORAGE & RLS: APLIKASI TEMUBARANG
-- Target: Supabase (PostgreSQL 15+)
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- 1. FUNGSI HELPER TIMESTAMP & AUTO-PROFILE
-- ============================================================================

-- Memperbarui kolom updated_at secara otomatis sebelum UPDATE
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Membuat baris profil otomatis saat pengguna mendaftar via Supabase Auth
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, full_name, whatsapp_number)
    VALUES (
        NEW.id,
        COALESCE(NULLIF(TRIM(NEW.raw_user_meta_data ->> 'full_name'), ''), 'Pengguna TemuBarang'),
        COALESCE(NULLIF(TRIM(NEW.raw_user_meta_data ->> 'whatsapp_number'), ''), '')
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ============================================================================
-- 2. PEMBUATAN TABEL
-- ============================================================================

-- A. Tabel Profiles (Data Pengguna)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    whatsapp_number TEXT NOT NULL DEFAULT '',
    avatar_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- B. Tabel Categories (Kategori Barang)
CREATE TABLE IF NOT EXISTS public.categories (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    icon_name TEXT NOT NULL DEFAULT 'category',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- C. Tabel Areas (Zona / Area Kampus & Kota)
CREATE TABLE IF NOT EXISTS public.areas (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- D. Tabel Items (Laporan Barang Hilang & Temuan)
CREATE TABLE IF NOT EXISTS public.items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    category_id INTEGER REFERENCES public.categories(id) ON DELETE SET NULL,
    area_id INTEGER REFERENCES public.areas(id) ON DELETE SET NULL,
    type TEXT NOT NULL CHECK (type IN ('lost', 'found')),
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    location_detail TEXT NOT NULL,
    incident_date TIMESTAMPTZ NOT NULL,
    image_url TEXT,
    whatsapp_contact TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'resolved')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- 3. INDEXES UNTUK PERFORMA QUERY
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_items_status_type_created
    ON public.items(status, type, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_items_user_id
    ON public.items(user_id, status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_items_category_id
    ON public.items(category_id);
CREATE INDEX IF NOT EXISTS idx_items_area_id
    ON public.items(area_id);

-- ============================================================================
-- 4. TRIGGERS
-- ============================================================================
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

DROP TRIGGER IF EXISTS set_profiles_updated_at ON public.profiles;
CREATE TRIGGER set_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS set_items_updated_at ON public.items;
CREATE TRIGGER set_items_updated_at
    BEFORE UPDATE ON public.items
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ============================================================================
-- 5. KONFIGURASI ROW LEVEL SECURITY (RLS)
-- ============================================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.areas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.items ENABLE ROW LEVEL SECURITY;

-- Policy: PROFILES
DROP POLICY IF EXISTS "Pengguna login dapat melihat profil" ON public.profiles;
CREATE POLICY "Pengguna login dapat melihat profil"
    ON public.profiles FOR SELECT
    TO authenticated
    USING (true);

DROP POLICY IF EXISTS "Pengguna hanya dapat membuat profil sendiri" ON public.profiles;
CREATE POLICY "Pengguna hanya dapat membuat profil sendiri"
    ON public.profiles FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Pengguna hanya dapat mengubah profil sendiri" ON public.profiles;
CREATE POLICY "Pengguna hanya dapat mengubah profil sendiri"
    ON public.profiles FOR UPDATE
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- Policy: CATEGORIES
DROP POLICY IF EXISTS "Pengguna login dapat membaca kategori" ON public.categories;
CREATE POLICY "Pengguna login dapat membaca kategori"
    ON public.categories FOR SELECT
    TO authenticated
    USING (true);

-- Policy: AREAS
DROP POLICY IF EXISTS "Pengguna login dapat membaca area" ON public.areas;
CREATE POLICY "Pengguna login dapat membaca area"
    ON public.areas FOR SELECT
    TO authenticated
    USING (true);

-- Policy: ITEMS
DROP POLICY IF EXISTS "Pengguna login dapat melihat laporan barang" ON public.items;
CREATE POLICY "Pengguna login dapat melihat laporan barang"
    ON public.items FOR SELECT
    TO authenticated
    USING (true);

DROP POLICY IF EXISTS "Pengguna login dapat membuat laporan barang" ON public.items;
CREATE POLICY "Pengguna login dapat membuat laporan barang"
    ON public.items FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Pemilik dapat mengubah laporan miliknya" ON public.items;
CREATE POLICY "Pemilik dapat mengubah laporan miliknya"
    ON public.items FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Pemilik dapat menghapus laporan miliknya" ON public.items;
CREATE POLICY "Pemilik dapat menghapus laporan miliknya"
    ON public.items FOR DELETE
    TO authenticated
    USING (auth.uid() = user_id);

-- ============================================================================
-- 6. SUPABASE STORAGE BUCKET & RLS (item-images)
-- ============================================================================
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'item-images',
    'item-images',
    true,
    2097152, -- Maksimal 2 MB per foto terkompresi
    ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
    public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

DROP POLICY IF EXISTS "Gambar barang dapat diakses publik" ON storage.objects;
CREATE POLICY "Gambar barang dapat diakses publik"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'item-images');

DROP POLICY IF EXISTS "Pengguna login dapat mengunggah gambar ke foldernya" ON storage.objects;
CREATE POLICY "Pengguna login dapat mengunggah gambar ke foldernya"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (
        bucket_id = 'item-images'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );

DROP POLICY IF EXISTS "Pengguna dapat memperbarui gambar miliknya" ON storage.objects;
CREATE POLICY "Pengguna dapat memperbarui gambar miliknya"
    ON storage.objects FOR UPDATE
    TO authenticated
    USING (
        bucket_id = 'item-images'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );

DROP POLICY IF EXISTS "Pengguna dapat menghapus gambar miliknya" ON storage.objects;
CREATE POLICY "Pengguna dapat menghapus gambar miliknya"
    ON storage.objects FOR DELETE
    TO authenticated
    USING (
        bucket_id = 'item-images'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );

-- ============================================================================
-- 7. DATA AWAL (SEED DATA)
-- ============================================================================
INSERT INTO public.categories (name, icon_name) VALUES
    ('Elektronik', 'devices'),
    ('Dokumen & Kartu', 'badge'),
    ('Dompet & Tas', 'wallet'),
    ('Kunci', 'key'),
    ('Kendaraan', 'directions_car'),
    ('Aksesoris', 'watch'),
    ('Lainnya', 'category')
ON CONFLICT (name) DO NOTHING;

INSERT INTO public.areas (name) VALUES
    ('Area Kampus Pusat'),
    ('Fakultas / Gedung Kuliah'),
    ('Perpustakaan & Kantin'),
    ('Parkiran & Asrama'),
    ('Area Kota / Umum'),
    ('Lainnya')
ON CONFLICT (name) DO NOTHING;
