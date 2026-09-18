import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'models/role.dart';
import 'screens/admin_users_screen.dart' deferred as admin_screen;
import 'screens/book_form_screen.dart';
import 'screens/book_list_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/forbidden_screen.dart';
import 'screens/login_screen.dart';
import 'screens/reader_loans_screen.dart';
import 'screens/register_screen.dart';
import 'state/auth_notifier.dart';
import 'widgets/adaptive_scaffold.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>();

class _DeferredAdminUsersScreen extends StatelessWidget {
  const _DeferredAdminUsersScreen();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: admin_screen.loadLibrary(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return admin_screen.AdminUsersScreen();
        }
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}

GoRouter buildRouter(AuthNotifier auth) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    refreshListenable: auth,
    initialLocation: '/',
    redirect: (context, state) {
      final loggedIn = auth.isAuthenticated;
      final target = state.matchedLocation;
      final isPublic = target == '/login' || target == '/register';

      if (!loggedIn && !isPublic) {
        final from = Uri.encodeComponent(state.uri.toString());
        return '/login?from=$from';
      }

      if (loggedIn && isPublic) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (c, s) => LoginScreen(from: s.uri.queryParameters['from']),
      ),
      GoRoute(
        path: '/register',
        builder: (c, s) => const RegisterScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          final destinations = <NavigationDestinationData>[
            const NavigationDestinationData(
              icon: Icons.dashboard_outlined,
              selectedIcon: Icons.dashboard,
              label: 'Главная',
            ),
            const NavigationDestinationData(
              icon: Icons.menu_book_outlined,
              selectedIcon: Icons.menu_book,
              label: 'Каталог',
            ),
            if (auth.has(Role.reader))
              const NavigationDestinationData(
                icon: Icons.bookmark_border,
                selectedIcon: Icons.bookmark,
                label: 'Выдачи',
              ),
            if (auth.has(Role.admin))
              const NavigationDestinationData(
                icon: Icons.admin_panel_settings_outlined,
                selectedIcon: Icons.admin_panel_settings,
                label: 'Админ',
              ),
          ];

          final routePaths = <String>[
            '/',
            '/books',
            if (auth.has(Role.reader)) '/my-loans',
            if (auth.has(Role.admin)) '/admin/users',
          ];

          final loc = state.matchedLocation;
          int currentIndex = 0;
          if (loc.startsWith('/books')) {
            currentIndex = routePaths.indexOf('/books');
          } else if (loc.startsWith('/my-loans')) {
            currentIndex = routePaths.indexOf('/my-loans');
          } else if (loc.startsWith('/admin/users')) {
            currentIndex = routePaths.indexOf('/admin/users');
          } else {
            currentIndex = 0;
          }

          if (currentIndex < 0) currentIndex = 0;

          return AdaptiveScaffold(
            selectedIndex: currentIndex,
            onDestinationSelected: (idx) {
              if (idx >= 0 && idx < routePaths.length) {
                context.go(routePaths[idx]);
              }
            },
            destinations: destinations,
            body: child,
          );
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (c, s) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/books',
            builder: (c, s) =>
                BookListScreen(queryParams: s.uri.queryParameters),
            routes: [
              GoRoute(
                path: 'new',
                builder: (c, s) => const BookFormScreen(),
                redirect: (c, s) =>
                    auth.has(Role.librarian) ? null : '/forbidden',
              ),
              GoRoute(
                path: ':id/edit',
                builder: (c, s) => BookFormScreen(
                    id: int.tryParse(s.pathParameters['id'] ?? '')),
                redirect: (c, s) =>
                    auth.has(Role.librarian) ? null : '/forbidden',
              ),
            ],
          ),
          GoRoute(
            path: '/my-loans',
            builder: (c, s) => const ReaderLoansScreen(),
            redirect: (c, s) => auth.has(Role.reader) ? null : '/forbidden',
          ),
          GoRoute(
            path: '/admin/users',
            builder: (c, s) => const _DeferredAdminUsersScreen(),
            redirect: (c, s) => auth.has(Role.admin) ? null : '/forbidden',
          ),
          GoRoute(
            path: '/forbidden',
            builder: (c, s) => const ForbiddenScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (c, s) => Scaffold(
      body: Center(
        child: Text('Страница не найдена: ${s.uri}'),
      ),
    ),
  );
}
