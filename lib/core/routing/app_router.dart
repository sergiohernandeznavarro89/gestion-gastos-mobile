import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/expenses/presentation/home_screen.dart';
import '../../features/transactions/presentation/transactions_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/categories/presentation/categories_screen.dart';
import '../../features/accounts/presentation/accounts_screen.dart';
import '../../features/auth/presentation/auth_provider.dart';
import '../presentation/main_layout.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  final isAuth = authState.value ?? false;

  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      if (authState.isLoading && !authState.hasValue) return null;

      final isGoingToLogin = state.uri.path == '/login';
      final isGoingToRegister = state.uri.path == '/register';
      final isLoggingInOrRegistering = isGoingToLogin || isGoingToRegister;

      if (!isAuth && !isLoggingInOrRegistering) return '/login';
      if (isAuth && isLoggingInOrRegistering) return '/home';

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainLayout(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/transactions',
                builder: (context, state) => const TransactionsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'accounts',
                    builder: (context, state) => const AccountsScreen(),
                  ),
                  GoRoute(
                    path: 'categories',
                    builder: (context, state) => const CategoriesScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
