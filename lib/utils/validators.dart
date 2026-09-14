class AppValidators {
  static String? requiredField(String? value, [String message = 'Поле обязательно для заполнения']) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }
    return null;
  }

  static String? minLength(String? value, int min, [String? message]) {
    if (value == null || value.trim().length < min) {
      return message ?? 'Минимальная длина - $min символов';
    }
    return null;
  }

  static String? maxLength(String? value, int max, [String? message]) {
    if (value != null && value.trim().length > max) {
      return message ?? 'Максимальная длина - $max символов';
    }
    return null;
  }

  static String? intRange(String? value, int min, int max, [String? message]) {
    if (value == null || value.trim().isEmpty) return 'Введите число';
    final n = int.tryParse(value.trim());
    if (n == null) return 'Введите целое число';
    if (n < min || n > max) {
      return message ?? 'Значение должно быть от $min до $max';
    }
    return null;
  }

  static String? positiveInt(String? value, [String? message]) {
    if (value == null || value.trim().isEmpty) return 'Введите число';
    final n = int.tryParse(value.trim());
    if (n == null || n <= 0) {
      return message ?? 'Число должно быть больше 0';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Введите email';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Некорректный формат email (пример: user@mail.ru)';
    }
    return null;
  }

  static String? isbn(String? value) {
    if (value == null || value.trim().isEmpty) return 'Введите ISBN';
    final clean = value.replaceAll('-', '').trim();
    if (clean.length != 10 && clean.length != 13) {
      return 'ISBN должен содержать 10 или 13 цифр';
    }
    return null;
  }
}