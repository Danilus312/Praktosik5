import 'package:flutter_test/flutter_test.dart';
import 'package:library_web/utils/validators.dart';

void main() {
  group('AppValidators Unit Tests', () {
    test('Обязательное поле отклоняет null, пустые строки и пробелы', () {
      expect(AppValidators.requiredField(null), isNotNull);
      expect(AppValidators.requiredField(''), isNotNull);
      expect(AppValidators.requiredField('   '), isNotNull);
      expect(AppValidators.requiredField('Война и мир'), isNull);
    });

    test('Проверка минимальной длины строки', () {
      expect(AppValidators.minLength(null, 3), isNotNull);
      expect(AppValidators.minLength('ab', 3), isNotNull);
      expect(AppValidators.minLength('abc', 3), isNull);
      expect(AppValidators.minLength('abcd', 3), isNull);
    });

    test('Проверка максимальной длины строки', () {
      expect(AppValidators.maxLength('123456', 5), isNotNull);
      expect(AppValidators.maxLength('12345', 5), isNull);
      expect(AppValidators.maxLength(null, 5), isNull);
    });

    test('Проверка целочисленного диапазона intRange', () {
      expect(AppValidators.intRange(null, 1500, 2026), isNotNull);
      expect(AppValidators.intRange('не_число', 1500, 2026), isNotNull);
      expect(AppValidators.intRange('1499', 1500, 2026), isNotNull);
      expect(AppValidators.intRange('2027', 1500, 2026), isNotNull);
      expect(AppValidators.intRange('1869', 1500, 2026), isNull);
    });

    test('Проверка положительного целого числа positiveInt', () {
      expect(AppValidators.positiveInt(null), isNotNull);
      expect(AppValidators.positiveInt('0'), isNotNull);
      expect(AppValidators.positiveInt('-5'), isNotNull);
      expect(AppValidators.positiveInt('10'), isNull);
    });

    test('Проверка корректности адреса электронной почты', () {
      expect(AppValidators.email(null), isNotNull);
      expect(AppValidators.email(''), isNotNull);
      expect(AppValidators.email('invalid-email'), isNotNull);
      expect(AppValidators.email('test@domain'), isNotNull);
      expect(AppValidators.email('reader@mail.ru'), isNull);
    });

    test('Проверка валидации ISBN', () {
      expect(AppValidators.isbn(null), isNotNull);
      expect(AppValidators.isbn(''), isNotNull);
      expect(AppValidators.isbn('12345'), isNotNull);
      expect(AppValidators.isbn('978-5-389-06256-6'), isNull);
      expect(AppValidators.isbn('0-306-40615-2'), isNull);
    });
  });
}
