import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:temubarang/core/config/app_config.dart';
import 'package:temubarang/core/theme/app_theme.dart';
import 'package:temubarang/features/auth/presentation/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (AppConfig.isConfigured) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
  }

  runApp(const ProviderScope(child: TemuBarangApp()));
}

class TemuBarangApp extends StatelessWidget {
  const TemuBarangApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TemuBarang',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const AuthGate(),
    );
  }
}
