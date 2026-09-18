enum Role {
  reader(1, 'Читатель'),
  librarian(2, 'Библиотекарь'),
  admin(3, 'Администратор');

  final int level;
  final String label;
  const Role(this.level, this.label);

  static Role fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'admin':
        return Role.admin;
      case 'librarian':
        return Role.librarian;
      default:
        return Role.reader;
    }
  }
}
