import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:temubarang/features/auth/data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(Supabase.instance.client);
});

final authSessionProvider = StreamProvider<Session?>((ref) async* {
  final repo = ref.read(authRepositoryProvider);
  yield repo.currentSession;
  yield* repo.sessionStream;
});
