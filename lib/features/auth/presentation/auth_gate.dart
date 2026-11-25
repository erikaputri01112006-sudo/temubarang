import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:temubarang/core/config/app_config.dart';
import 'package:temubarang/features/auth/presentation/auth_provider.dart';
import 'package:temubarang/features/auth/presentation/login_page.dart';
import 'package:temubarang/features/items/presentation/main_shell_page.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!AppConfig.isConfigured) {
      return const _MissingConfigScreen();
    }

    final sessionAsync = ref.watch(authSessionProvider);

    return sessionAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Gagal memeriksa sesi masuk: $err'),
          ),
        ),
      ),
      data: (session) {
        if (session == null) {
          return const LoginPage();
        }
        return const MainShellPage();
      },
    );
  }
}

class _MissingConfigScreen extends StatelessWidget {
  const _MissingConfigScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.settings_suggest_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Konfigurasi Supabase Belum Diatur',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Aplikasi perlu dijalankan atau di-build dengan parameter:\n'
                  '--dart-define=SUPABASE_URL=...\n'
                  '--dart-define=SUPABASE_ANON_KEY=...',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
