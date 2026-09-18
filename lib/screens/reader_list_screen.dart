import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../repositories/app_repositories.dart';

class ReaderListScreen extends StatefulWidget {
  const ReaderListScreen({super.key});

  @override
  State<ReaderListScreen> createState() => _ReaderListScreenState();
}

class _ReaderListScreenState extends State<ReaderListScreen> {
  @override
  Widget build(BuildContext context) {
    final repo = context.watch<PersistentLibraryRepository>();
    final readers = repo.readers.where((r) => !r.isDeleted).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Читатели библиотеки'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/books'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add),
        label: const Text('Новый читатель'),
        onPressed: () => context.go('/readers/new'),
      ),
      body: readers.isEmpty
          ? const Center(child: Text('Читатели не найдены'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: readers.length,
              itemBuilder: (ctx, i) {
                final r = readers[i];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(r.fullName),
                    subtitle: Text(
                        'Email: ${r.email} | Билет: ${r.card.cardNumber} (${r.card.isActive ? 'Активен' : 'Заблокирован'})'),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => context.go('/readers/${r.id}/edit'),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
