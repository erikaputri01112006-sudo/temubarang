import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:temubarang/features/auth/presentation/auth_provider.dart';
import 'package:temubarang/features/profile/data/profile_repository.dart';
import 'package:temubarang/features/profile/domain/profile_model.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(Supabase.instance.client);
});

final currentProfileProvider = FutureProvider<UserProfile?>((ref) async {
  // Memicu reload profil setiap kali status autentikasi berubah
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) return null;

  return ref.read(profileRepositoryProvider).getCurrentProfile();
});
