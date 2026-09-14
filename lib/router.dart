import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'models/role.dart';
import 'screens/admin_users_screen.dart';
import 'screens/book_form_screen.dart';
import 'screens/book_list_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/forbidden_screen.dart';
import 'screens/login_screen.dart';
import 'screens/reader_loans_screen.dart';
import 'screens/register_screen.dart';
import 'state/auth_notifier.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

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
      GoRoute(
        path: '/',
        builder: (c, s) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/books',
        builder: (c, s) => BookListScreen(queryParams: s.uri.queryParameters),
        routes: [
          GoRoute(
            path: 'new',
            builder: (c, s) => const BookFormScreen(),
            redirect: (c, s) => auth.has(Role.librarian) ? null : '/forbidden',
          ),
          GoRoute(
            path: ':id/edit',
            builder: (c, s) => BookFormScreen(id: int.tryParse(s.pathParameters['id'] ?? '')),
            redirect: (c, s) => auth.has(Role.librarian) ? null : '/forbidden',
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
        builder: (c, s) => const AdminUsersScreen(),
        redirect: (c, s) => auth.has(Role.admin) ? null : '/forbidden',
      ),
      GoRoute(
        path: '/forbidden',
        builder: (c, s) => const ForbiddenScreen(),
      ),
    ],
    errorBuilder: (c, s) => Scaffold(
      body: Center(
        child: Text('Страница не найдена: ${s.uri}'),
      ),
    ),
  );
}