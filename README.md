# TemuBarang — Aplikasi Pencarian & Pelaporan Barang Hilang/Temuan

Aplikasi mobile Android berbasis **Flutter (Material 3 + Riverpod)** dan **Supabase (Auth, PostgreSQL + RLS, Storage)** yang dirancang khusus untuk mahasiswa dan masyarakat umum.

## Fitur Utama
- **Autentikasi Wajib**: Login & Register menggunakan Email + Password (profil dan nomor WhatsApp tersimpan otomatis melalui trigger database).
- **Posting Laporan**: Melaporkan **Barang Hilang** atau **Barang Temuan** lengkap dengan foto terkompresi otomatis, kategori, area/zona, detail lokasi, dan tanggal kejadian.
- **Pencarian & Filter**: Pencarian teks bebas serta filter berdasarkan jenis laporan, kategori barang, dan area.
- **Kontak WhatsApp Langsung**: Menghubungi pelapor/penemu via `wa.me` dengan templat pesan otomatis (tombol otomatis disembunyikan jika status laporan sudah selesai).
- **Riwayat & Status Laporan**: Mengelola laporan aktif dan menandai laporan sebagai **Selesai** ketika barang sudah kembali.

---

## Panduan Setup Supabase (Gratis)

1. Buat proyek baru di [Supabase](https://supabase.com/).
2. Buka menu **SQL Editor**, salin seluruh isi file `database/database_schema.sql`, lalu jalankan (**Run**).
3. Nonaktifkan verifikasi email agar pendaftaran langsung masuk (menghindari batas email gratis 2–4 email/jam):
   - Masuk ke **Authentication -> Providers -> Email**.
   - Matikan opsi **Confirm email**, lalu klik **Save**.
4. Ambil **Project URL** dan **anon public key** di menu **Project Settings -> API**.

---

## Panduan Build APK Otomatis via GitHub Actions

1. Push proyek ini ke repository GitHub Anda (`main` branch).
2. Di repository GitHub, buka **Settings -> Secrets and variables -> Actions -> New repository secret**, lalu tambahkan dua secret berikut:
   - `SUPABASE_URL`: URL proyek Supabase Anda
   - `SUPABASE_ANON_KEY`: Anon Key proyek Supabase Anda
3. Buka tab **Actions** di GitHub dan jalankan workflow **Build Android APK** (atau akan berjalan otomatis saat Anda melakukan `git push` ke `main`).
4. Setelah selesai, unduh file **`temubarang-release-apk`** dari bagian **Artifacts** di halaman workflow run tersebut, ekstrak, lalu instal `app-release.apk` di HP Android Anda.

---

## Menjalankan di Lokal (Jika Flutter SDK Terpasang)

Salin file `dart_defines.example.json` menjadi `dart_defines.json`, isi URL & Anon Key Anda, lalu jalankan:

```bash
flutter pub get
flutter run --dart-define-from-file=dart_defines.json
```

Untuk build APK lokal:

```bash
flutter build apk --release --dart-define-from-file=dart_defines.json
```
