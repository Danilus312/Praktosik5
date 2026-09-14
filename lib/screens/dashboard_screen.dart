import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/role.dart';
import '../state/auth_notifier.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Библиотечная система'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '${user?.fullName ?? "Пользователь"} (${user?.role.label ?? ""})',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Выйти из системы',
            icon: const Icon(Icons.logout),
            onPressed: () => auth.logout(),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  color: Colors.teal.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.teal,
                          child: Icon(Icons.person, size: 36, color: Colors.white),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.fullName ?? '',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text('Логин: @${user?.username ?? ""} • Уровень доступа: ${user?.role.label}'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Доступные функциональные модули:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _buildNavCard(
                      context,
                      title: 'Каталог книг',
                      subtitle: 'Поиск, просмотр и фильтрация',
                      icon: Icons.menu_book,
                      color: Colors.blue,
                      route: '/books',
                    ),
                    if (auth.has(Role.reader))
                      _buildNavCard(
                        context,
                        title: 'Мои выдачи',
                        subtitle: 'Список книг на руках и продление',
                        icon: Icons.bookmark,
                        color: Colors.teal,
                        route: '/my-loans',
                      ),
                    if (auth.has(Role.librarian))
                      _buildNavCard(
                        context,
                        title: 'Новая книга',
                        subtitle: 'Внесение изданий в фонд (Библиотекарь)',
                        icon: Icons.add_box,
                        color: Colors.orange,
                        route: '/books/new',
                      ),
                    if (auth.has(Role.admin))
                      _buildNavCard(
                        context,
                        title: 'Пользователи и роли',
                        subtitle: 'Администрирование учетных записей',
                        icon: Icons.admin_panel_settings,
                        color: Colors.purple,
                        route: '/admin/users',
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String route,
  }) {
    return SizedBox(
      width: 380,
      child: Card(
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.go(route),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 32, color: color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}