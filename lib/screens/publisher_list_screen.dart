import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../repositories/app_repositories.dart';

class PublisherListScreen extends StatefulWidget {
  const PublisherListScreen({super.key});

  @override
  State<PublisherListScreen> createState() => _PublisherListScreenState();
}

class _PublisherListScreenState extends State<PublisherListScreen> {
  void _attemptDelete(BuildContext context, int publisherId, String name) {
    final repo = context.read<PersistentLibraryRepository>();
    final linkedBooks = repo.countBooksByPublisher(publisherId);

    if (linkedBooks > 0) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.warning, color: Colors.orange, size: 48),
          title: const Text('Отказ в удалении'),
          content: Text(
            'Невозможно удалить издательство "$name".\nК нему привязано $linkedBooks книг(и) в каталоге.\nСначала перенесите или удалите эти книги.',
          ),
          actions: [
            FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Понятно')),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Удаление издательства'),
          content: Text('Удалить издательство "$name"?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Отмена')),
            FilledButton(
              onPressed: () async {
                repo.publishers.removeWhere((p) => p.id == publisherId);
                await repo.savePublishers();
                if (ctx.mounted) Navigator.pop(ctx);
                setState(() {});
              },
              child: const Text('Удалить'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<PersistentLibraryRepository>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Издательства'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/books'),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: repo.publishers.length,
        itemBuilder: (ctx, i) {
          final p = repo.publishers[i];
          final bookCount = repo.countBooksByPublisher(p.id);
          return Card(
            child: ListTile(
              leading: const Icon(Icons.business),
              title: Text(p.name),
              subtitle: Text('Город: ${p.city} | Связанных книг: $bookCount'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _attemptDelete(context, p.id, p.name),
              ),
            ),
          );
        },
      ),
    );
  }
}
