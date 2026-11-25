import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:temubarang/core/utils/whatsapp_helper.dart';

class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  Stream<Session?> get sessionStream =>
      _client.auth.onAuthStateChange.map((event) => event.session);

  Session? get currentSession => _client.auth.currentSession;

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signUp({
    required String fullName,
    required String whatsappNumber,
    required String email,
    required String password,
  }) async {
    final normalizedWa = WhatsappHelper.normalizeNumber(whatsappNumber);

    await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'full_name': fullName.trim(),
        'whatsapp_number': normalizedWa,
      },
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  static String translateError(Object error) {
    if (error is AuthException) {
      final msg = error.message.toLowerCase();
      if (msg.contains('invalid login credentials')) {
        return 'Email atau kata sandi salah.';
      }
      if (msg.contains('user already registered')) {
        return 'Email sudah terdaftar. Silakan masuk.';
      }
      if (msg.contains('password should be at least')) {
        return 'Kata sandi minimal 6 karakter.';
      }
      if (msg.contains('email rate limit')) {
        return 'Terlalu banyak percobaan. Silakan tunggu beberapa saat.';
      }
      if (msg.contains('unable to validate email')) {
        return 'Format email tidak valid.';
      }
      return error.message;
    }
    return 'Terjadi gangguan koneksi. Periksa internet Anda dan coba lagi.';
  }
}
