import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// View placeholders for lazy loading setup
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/analytics/presentation/screens/dashboard_screen.dart';
import '../../features/tasks/presentation/screens/tasks_screen.dart';
import '../../features/habits/presentation/screens/habits_screen.dart';
import '../../features/journal/presentation/screens/journal_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../shared/widgets/responsive_navigation_shell.dart';
import '../database/database_service.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final db = DatabaseService.instance;

  return GoRouter(
    initialLocation: '/onboarding',
    redirect: (context, state) {
      final hasCompletedOnboarding = db.getSetting('onboarding_completed', defaultValue: false) as bool;
      final isBiometricsEnabled = db.getSetting('biometrics_enabled', defaultValue: false) as bool;
      final isAuthenticated = db.getSetting('session_authenticated', defaultValue: false) as bool;

      // Onboarding redirection
      if (!hasCompletedOnboarding && state.matchedLocation != '/onboarding') {
        return '/onboarding';
      }

      // If onboarding is done, but biometrics is enabled and not authenticated, redirect to login
      if (hasCompletedOnboarding && isBiometricsEnabled && !isAuthenticated && state.matchedLocation != '/login') {
        return '/login';
      }

      // If biometrics is NOT enabled or already authenticated, allow normal navigation
      if (state.matchedLocation == '/onboarding' && hasCompletedOnboarding) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return ResponsiveNavigationShell(
            currentPath: state.matchedLocation,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/tasks',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: TasksScreen(),
            ),
          ),
          GoRoute(
            path: '/habits',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HabitsScreen(),
            ),
          ),
          GoRoute(
            path: '/journal',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: JournalScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
        ],
      ),
    ],
  );
});
