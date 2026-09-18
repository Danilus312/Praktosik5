import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ReaderLoansScreen extends StatelessWidget {
  const ReaderLoansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои выдачи и продление срока (Читатель)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.all(16),
                children: [
                  ListTile(
                    leading: const Icon(Icons.book, color: Colors.teal),
                    title: const Text('1984 — Джордж Оруэлл'),
                    subtitle:
                        const Text('Срок возврата: до 28 сентября 2026 г.'),
                    trailing: OutlinedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Срок продлен на 14 дней')),
                        );
                      },
                      child: const Text('Продлить'),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.book, color: Colors.teal),
                    title: const Text('Мастер и Маргарита — М. Булгаков'),
                    subtitle:
                        const Text('Срок возврата: до 05 октября 2026 г.'),
                    trailing: OutlinedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Срок продлен на 14 дней')),
                        );
                      },
                      child: const Text('Продлить'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
