import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app_config.dart';
import 'core/pawly_theme.dart';
import 'data/pawly_repository.dart';
import 'providers/auth_controller.dart';
import 'screens/app_shell.dart';
import 'screens/auth/auth_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (AppConfig.isSupabaseConfigured) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabaseAnonKey,
    );
  }
  runApp(PawlyApp(isConfigured: AppConfig.isSupabaseConfigured));
}

class PawlyApp extends StatelessWidget {
  const PawlyApp({super.key, required this.isConfigured});
  final bool isConfigured;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Pawly | Pet care made simple',
    debugShowCheckedModeBanner: false,
    theme: pawlyTheme(),
    home: isConfigured
        ? MultiProvider(
            providers: [
              Provider(
                create: (_) => PawlyRepository(Supabase.instance.client),
              ),
              ChangeNotifierProvider(
                create: (_) => AuthController(Supabase.instance.client),
              ),
            ],
            child: const _AuthGate(),
          )
        : const _ConfigurationScreen(),
  );
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.user;
    if (user == null) return const AuthScreen();
    if (auth.needsPasswordUpdate) return const UpdatePasswordScreen();
    return AppShell(user: user);
  }
}

class _ConfigurationScreen extends StatelessWidget {
  const _ConfigurationScreen();
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: Color(0x1A167C80),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.key_outlined,
                            size: 34,
                            color: PawlyColors.teal,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Connect Pawly to Supabase',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'The app is ready, but it needs your Supabase project URL and publishable (anon) key at launch. They are deliberately not stored in the source code.',
                          textAlign: TextAlign.center,
                          style: TextStyle(height: 1.45),
                        ),
                        const SizedBox(height: 22),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: PawlyColors.cream,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const SelectableText(
                            'flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLISHABLE_KEY',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              height: 1.45,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Before launching, run supabase/schema.sql once in Supabase SQL Editor and add the listed redirect URLs in Supabase Authentication settings.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, height: 1.35),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
