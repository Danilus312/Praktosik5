import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:library_web/models/app_user.dart';
import 'package:library_web/models/book.dart';
import 'package:library_web/models/book_query.dart';
import 'package:library_web/models/page_result.dart';
import 'package:library_web/models/role.dart';
import 'package:library_web/repositories/book_repository.dart';
import 'package:library_web/repositories/cached_dictionary_repository.dart';
import 'package:library_web/screens/book_form_screen.dart';
import 'package:library_web/screens/book_list_screen.dart';
import 'package:library_web/screens/dashboard_screen.dart';
import 'package:library_web/state/auth_notifier.dart';
import 'package:library_web/state/book_list_notifier.dart';
import 'package:provider/provider.dart';

class FakeAuthNotifier extends ChangeNotifier implements AuthNotifier {
  @override
  final AppUser? user;
  @override
  final String? accessToken;

  FakeAuthNotifier({this.user, this.accessToken = 'dummy_token'});

  @override
  bool get isAuthenticated => user != null;

  @override
  bool has(Role role) => user != null && user!.role.level >= role.level;

  @override
  Future<void> restore() async {}

  @override
  Future<void> login(String username, String password) async {}

  @override
  Future<void> register(String username, String password, String fullName) async {}

  @override
  Future<void> refreshTokens() async {}

  @override
  Future<void> logout() async {}
}

class FakeBookRepository implements BookRepository {
  final List<Book> items;
  final bool shouldFail;
  final Duration delay;

  FakeBookRepository({
    this.items = const [],
    this.shouldFail = false,
    this.delay = Duration.zero,
  });

  @override
  Future<PageResult<Book>> find(BookQuery query) async {
    if (delay > Duration.zero) await Future.delayed(delay);
    if (shouldFail) throw Exception('Network error');
    return PageResult(
      items: items,
      total: items.length,
      page: query.page,
      size: query.size,
    );
  }

  @override
  Future<Book?> findById(int id) async =>
      items.isEmpty ? null : items.firstWhere((b) => b.id == id, orElse: () => items.first);

  @override
  Future<Book> create(Book book) async => book;

  @override
  Future<Book> update(Book book) async => book;

  @override
  Future<void> softDelete(int id) async {}

  @override
  Future<void> hardDelete(int id) async {}

  @override
  Future<void> restore(int id) async {}

  @override
  Future<int> deleteMany(List<int> ids) async => 0;
}

Widget wrapWithProviders(
  Widget child, {
  BookRepository? repo,
  AuthNotifier? auth,
}) {
  final dio = Dio();
  final bookRepo = repo ?? FakeBookRepository();
  final authNotifier = auth ??
      FakeAuthNotifier(
        user: const AppUser(
          id: 1,
          username: 'admin',
          fullName: 'Admin User',
          role: Role.admin,
        ),
      );

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthNotifier>.value(value: authNotifier),
      Provider<Dio>.value(value: dio),
      Provider<CachedDictionaryRepository>(
        create: (_) => CachedDictionaryRepository(dio),
      ),
      Provider<BookRepository>.value(value: bookRepo),
      ChangeNotifierProvider<BookListNotifier>(
        create: (_) => BookListNotifier(bookRepo)..load(),
      ),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, __) => child),
        ],
      ),
    ),
  );
}

void main() {
  group('Widget Tests (Full Suite)', () {
    testWidgets('1. Loading indicator is displayed during fetch', (tester) async {
      final fakeRepo = FakeBookRepository(
        items: [],
        delay: const Duration(milliseconds: 500),
      );

      await tester.pumpWidget(wrapWithProviders(const BookListScreen(), repo: fakeRepo));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Загрузка данных с сервера...'), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('2. Empty state message is displayed when list has no items', (tester) async {
      final fakeRepo = FakeBookRepository(items: []);

      await tester.pumpWidget(wrapWithProviders(const BookListScreen(), repo: fakeRepo));
      await tester.pumpAndSettle();

      expect(find.text('По заданным критериям книг не найдено'), findsOneWidget);
      expect(find.byIcon(Icons.search_off), findsOneWidget);
    });

    testWidgets('3. Error state displays reload button and triggers retry', (tester) async {
      final fakeRepo = FakeBookRepository(shouldFail: true);

      await tester.pumpWidget(wrapWithProviders(const BookListScreen(), repo: fakeRepo));
      await tester.pumpAndSettle();

      expect(find.text('Повторить'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);

      await tester.tap(find.text('Повторить'));
      await tester.pumpAndSettle();
    });

    testWidgets('4. Form validation displays required field error', (tester) async {
      await tester.pumpWidget(wrapWithProviders(const BookFormScreen()));
      await tester.pumpAndSettle();

      final saveBtn = find.text('Создать книгу');
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pump();

      expect(find.text('Поле обязательно для заполнения'), findsOneWidget);
    });

    testWidgets('5. Unauthorized actions are hidden for reader role', (tester) async {
      final readerAuth = FakeAuthNotifier(
        user: const AppUser(
          id: 3,
          username: 'reader',
          fullName: 'Reader User',
          role: Role.reader,
        ),
      );

      await tester.pumpWidget(wrapWithProviders(const DashboardScreen(), auth: readerAuth));
      await tester.pumpAndSettle();

      expect(find.text('Мои выдачи'), findsOneWidget);
      expect(find.text('Пользователи и роли'), findsNothing);
      expect(find.text('Новая книга'), findsNothing);
    });
  });
}