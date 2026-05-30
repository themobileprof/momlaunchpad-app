import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/profile_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'config/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.initialize();
  
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
      theme: applyGoogleFonts(buildAppTheme()),
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
    final profileState = ref.watch(profileProvider);

    if (authState.isLoading || (authState.isLoggedIn && profileState.isLoading)) {
      return const SplashScreen();
    }

    if (authState.isLoggedIn && authState.user != null) {
      if (profileState.profile != null && !profileState.profile!.onboardingCompleted) {
        return const OnboardingScreen();
      }
      return const HomeScreen();
    }

    return const LoginScreen();
  }
}
