import 'package:flutter_test/flutter_test.dart';
import 'package:library_web/models/app_user.dart';
import 'package:library_web/models/role.dart';

void main() {
  group('Тестирование матрицы ролей и прав (ПР5)', () {
    test('1. Иерархия уровней доступа ролей', () {
      expect(Role.admin.level > Role.librarian.level, isTrue);
      expect(Role.librarian.level > Role.reader.level, isTrue);
      expect(Role.admin.level, 3);
    });

    test('2. Администратор обладает всеми правами нижестоящих ролей', () {
      const admin = AppUser(id: 1, username: 'admin', fullName: 'Админ', role: Role.admin);
      expect(admin.role.level >= Role.admin.level, isTrue);
      expect(admin.role.level >= Role.librarian.level, isTrue);
      expect(admin.role.level >= Role.reader.level, isTrue);
    });

    test('3. Библиотекарь не имеет прав администратора', () {
      const lib = AppUser(id: 2, username: 'lib', fullName: 'Библиотекарь', role: Role.librarian);
      expect(lib.role.level >= Role.librarian.level, isTrue);
      expect(lib.role.level >= Role.admin.level, isFalse);
    });

    test('4. Читатель не имеет доступа к редактированию фонда', () {
      const reader = AppUser(id: 3, username: 'reader', fullName: 'Читатель', role: Role.reader);
      expect(reader.role.level >= Role.reader.level, isTrue);
      expect(reader.role.level >= Role.librarian.level, isFalse);
      expect(reader.role.level >= Role.admin.level, isFalse);
    });

    test('5. Разбор ролей из серверного JSON', () {
      final user = AppUser.fromJson({'id': 10, 'username': 'boss', 'role': 'admin'});
      expect(user.role, Role.admin);
      final fallback = AppUser.fromJson({'id': 11, 'username': 'unknown', 'role': 'something'});
      expect(fallback.role, Role.reader);
    });
  });
}