import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/api_client.dart';
import 'repositories/api_book_repository.dart';
import 'repositories/author_repository.dart';
import 'repositories/book_repository.dart';
import 'repositories/cached_dictionary_repository.dart';
import 'repositories/in_memory_author_repository.dart';
import 'router.dart';
import 'state/auth_notifier.dart';
import 'state/author_list_notifier.dart';
import 'state/book_list_notifier.dart';
import 'widgets/inactivity_watcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  final prefs = await SharedPreferences.getInstance();
  final basicDio = buildDio(authNotifier: null);
  final authNotifier = AuthNotifier(prefs, basicDio);

  await authNotifier.restore();

  final authenticatedDio = buildDio(authNotifier: authNotifier);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthNotifier>.value(value: authNotifier),
        Provider<Dio>.value(value: authenticatedDio),
        Provider<CachedDictionaryRepository>(
          create: (context) => CachedDictionaryRepository(context.read<Dio>()),
        ),
        Provider<BookRepository>(
          create: (context) => ApiBookRepository(context.read<Dio>()),
        ),
        Provider<AuthorRepository>(create: (_) => InMemoryAuthorRepository()),
        ChangeNotifierProvider(
          create: (context) =>
              BookListNotifier(context.read<BookRepository>())..load(),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              AuthorListNotifier(context.read<AuthorRepository>())..load(),
        ),
      ],
      child: const LibraryApp(),
    ),
  );
}

class LibraryApp extends StatelessWidget {
  const LibraryApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authNotifier = context.watch<AuthNotifier>();
    final router = buildRouter(authNotifier);

    return InactivityWatcher(
      child: MaterialApp.router(
        title: 'Библиотечная система (Auth & Roles)',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          useMaterial3: true,
        ),
        routerConfig: router,
      ),
    );
  }
}
