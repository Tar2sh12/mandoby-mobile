import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/confirm_email_screen.dart';
import '../screens/main_shell.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/shifts/shifts_screen.dart';
import '../screens/shifts/shift_detail_screen.dart';
import '../screens/people/people_screen.dart';
import '../screens/people/person_detail_screen.dart';
import '../screens/items/items_screen.dart';
import '../screens/transactions/transactions_screen.dart';
import '../screens/profile/profile_screen.dart';

final _shellRoutes = ['/dashboard', '/shifts', '/people', '/items', '/transactions'];

int _shellIndex(String location) {
  if (location.startsWith('/dashboard')) return 0;
  if (location.startsWith('/shifts')) return 1;
  if (location.startsWith('/people')) return 2;
  if (location.startsWith('/items')) return 3;
  if (location.startsWith('/transactions')) return 4;
  return 0;
}

GoRouter createRouter(BuildContext context) {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);

  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (ctx, state) {
      final loggedIn = authProvider.isLoggedIn;
      final loading = authProvider.loading;
      if (loading) return null;
      final publicRoutes = ['/login', '/signup', '/confirm-email'];
      final isPublic = publicRoutes.any((r) => state.matchedLocation.startsWith(r));
      if (!loggedIn && !isPublic) return '/login';
      if (loggedIn && isPublic) return '/dashboard';
      return null;
    },
    refreshListenable: authProvider,
    routes: [
      // Auth routes (no shell)
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
      GoRoute(
        path: '/confirm-email',
        builder: (_, state) => ConfirmEmailScreen(email: state.extra as String?),
      ),

      // Profile (outside shell nav)
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),

      // Person detail (outside shell nav)
      GoRoute(
        path: '/people/:id',
        builder: (_, state) => PersonDetailScreen(personId: state.pathParameters['id']!),
      ),

      // Shift detail (outside shell nav)
      GoRoute(
        path: '/shifts/:id',
        builder: (_, state) => ShiftDetailScreen(shiftId: state.pathParameters['id']!),
      ),

      // Shell routes (with bottom nav)
      ShellRoute(
        builder: (_, state, child) => MainShell(currentIndex: _shellIndex(state.matchedLocation), child: child),
        routes: [
          GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
          GoRoute(path: '/shifts', builder: (_, __) => const ShiftsScreen()),
          GoRoute(path: '/people', builder: (_, __) => const PeopleScreen()),
          GoRoute(path: '/items', builder: (_, __) => const ItemsScreen()),
          GoRoute(path: '/transactions', builder: (_, __) => const TransactionsScreen()),
        ],
      ),
    ],
  );
}
