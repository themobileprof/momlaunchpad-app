import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/theme_provider.dart';
import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/service_providers.dart';
import 'screens/account_load_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'config/app_config.dart';
import 'widgets/analytics_route_observer.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.initialize();

  final container = ProviderContainer();
  await container.read(analyticsServiceProvider).init();
  container.dispose();

  runApp(
    const ProviderScope(
      child: MomLaunchpadApp(),
    ),
  );
}

class MomLaunchpadApp extends ConsumerStatefulWidget {
  const MomLaunchpadApp({super.key});

  @override
  ConsumerState<MomLaunchpadApp> createState() => _MomLaunchpadAppState();
}

class _MomLaunchpadAppState extends ConsumerState<MomLaunchpadApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(analyticsServiceProvider).logAppOpen();
      ref.read(authProvider.notifier).refreshSessionIfLoggedIn();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themePreference = ref.watch(themePreferenceProvider);

    ref.listen(authProvider, (previous, next) {
      if (previous?.isLoggedIn == true && !next.isLoggedIn) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          rootNavigatorKey.currentState?.popUntil((route) => route.isFirst);
        });
      }
    });

    final analytics = ref.watch(analyticsServiceProvider);

    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      navigatorObservers: [AnalyticsRouteObserver(analytics)],
      title: 'MomLaunchpad',
      theme: applyGoogleFonts(buildAppLightTheme()),
      darkTheme: applyGoogleFonts(buildAppDarkTheme()),
      themeMode: themePreference.themeMode,
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
      final profile = profileState.profile;

      if (profile == null) {
        return AccountLoadScreen(
          errorMessage: profileState.error ??
              'Check your connection and try again.',
        );
      }

      if (!profile.onboardingCompleted) {
        return const OnboardingScreen();
      }
      return const HomeScreen();
    }

    return const LoginScreen();
  }
}
