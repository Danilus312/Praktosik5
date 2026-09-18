import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление пользователями и ролями (Администратор)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('Логин')),
                  DataColumn(label: Text('ФИО')),
                  DataColumn(label: Text('Роль')),
                  DataColumn(label: Text('Действия')),
                ],
                rows: const [
                  DataRow(cells: [
                    DataCell(Text('1')),
                    DataCell(Text('admin')),
                    DataCell(Text('Системный администратор')),
                    DataCell(Text('Администратор')),
                    DataCell(Icon(Icons.shield, color: Colors.purple)),
                  ]),
                  DataRow(cells: [
                    DataCell(Text('2')),
                    DataCell(Text('librarian')),
                    DataCell(Text('Иванова Мария Сергеевна')),
                    DataCell(Text('Библиотекарь')),
                    DataCell(Icon(Icons.edit, color: Colors.blue)),
                  ]),
                  DataRow(cells: [
                    DataCell(Text('3')),
                    DataCell(Text('reader')),
                    DataCell(Text('Петров Алексей Викторович')),
                    DataCell(Text('Читатель')),
                    DataCell(Icon(Icons.edit, color: Colors.blue)),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
