import 'package:flutter/material.dart';
import 'package:frontend/features/potholes/pothole_list_page.dart';
import 'package:go_router/go_router.dart';

import '../../features/splash/splash_page.dart';
import '../../features/onboarding/onboarding_page.dart';
import '../../features/home/home_page.dart';
import '../../features/gallery/gallery_page.dart';
import '../../features/settings/settings_page.dart';
import '../../features/pothole_report/screens/photo_selection_screen.dart';
import '../services/logging/app_logger.dart';
import '../widgets/main_layout.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    observers: [RouterObserver()],
    routes: [
      // Splash route (no bottom navigation)
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),

      // Onboarding route (no bottom navigation)
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),

      // Main shell with bottom navigation
      ShellRoute(
        builder: (context, state, child) => MainLayout(child: child),
        routes: [
          // Home route
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomePage(),
          ),

          // Pothole list route
          GoRoute(
            path: '/pothole',
            name: 'pothole',
            builder: (context, state) => const PotholeListPage(),
          ),

          // Gallery route
          GoRoute(
            path: '/gallery',
            name: 'gallery',
            builder: (context, state) => const GalleryPage(),
          ),

          // Settings route
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsPage(),
          ),

          // Photo selection route
          GoRoute(
            path: '/photo-selection',
            name: 'photo-selection',
            builder: (context, state) => const PhotoSelectionScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => ErrorPage(error: state.error),
    redirect: (context, state) {
      // Add any global redirect logic here
      return null;
    },
  );
}

class RouterObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    AppLogger.navigation(
      'PUSH',
      route.settings.name ?? 'unknown',
      previous: previousRoute?.settings.name,
    );
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    AppLogger.navigation(
      'POP',
      route.settings.name ?? 'unknown',
      previous: previousRoute?.settings.name,
    );
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    AppLogger.navigation(
      'REPLACE',
      newRoute?.settings.name ?? 'unknown',
      previous: oldRoute?.settings.name,
    );
  }
}

class ErrorPage extends StatelessWidget {
  final Exception? error;

  const ErrorPage({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              error?.toString() ?? 'Unknown error occurred',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}
