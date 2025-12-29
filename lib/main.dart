import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MomLaunchpadApp(),
    ),
  );
}

class MomLaunchpadApp extends ConsumerWidget {
  const MomLaunchpadApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'MomLaunchpad',
      theme: buildAppTheme(),
      debugShowCheckedModeBanner: false,
      home: const AppInitializer(),
    );
  }
}

/// Initializer to check auth status and route accordingly
class AppInitializer extends ConsumerWidget {
  const AppInitializer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState.isLoading) {
      return const SplashScreen();
    }

    if (authState.isLoggedIn && authState.user != null) {
      return const HomeScreen();
    }

    return const LoginScreen();
  }
}
