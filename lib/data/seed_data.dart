import '../models/author.dart';
import '../models/book.dart';
import '../models/genre.dart';
import '../models/library_card.dart';
import '../models/publisher.dart';
import '../models/reader.dart';

final List<Genre> seedGenres = [
  const Genre(id: 1, name: 'Классика'),
  const Genre(id: 2, name: 'Исторический'),
  const Genre(id: 3, name: 'Философия'),
  const Genre(id: 4, name: 'Антиутопия'),
  const Genre(id: 5, name: 'Фантастика'),
  const Genre(id: 6, name: 'Сатира'),
  const Genre(id: 7, name: 'Магический реализм'),
  const Genre(id: 8, name: 'Драматургия'),
];

final List<Publisher> seedPublishers = [
  const Publisher(id: 1, name: 'Азбука-Аттикус', city: 'Санкт-Петербург'),
  const Publisher(id: 2, name: 'Эксмо', city: 'Москва'),
  const Publisher(id: 3, name: 'АСТ', city: 'Москва'),
];

final List<Author> seedAuthors = [
  const Author(id: 1, firstName: 'Лев', lastName: 'Толстой', country: 'Россия', birthYear: 1828),
  const Author(id: 2, firstName: 'Фёдор', lastName: 'Достоевский', country: 'Россия', birthYear: 1821),
  const Author(id: 3, firstName: 'Джордж', lastName: 'Оруэлл', country: 'Великобритания', birthYear: 1903),
  const Author(id: 4, firstName: 'Михаил', lastName: 'Булгаков', country: 'Россия', birthYear: 1891),
  const Author(id: 5, firstName: 'Рэй', lastName: 'Брэдбери', country: 'США', birthYear: 1920),
  const Author(id: 6, firstName: 'Франц', lastName: 'Кафка', country: 'Австрия', birthYear: 1883),
  const Author(id: 7, firstName: 'Габриэль', lastName: 'Гарсиа Маркес', country: 'Колумбия', birthYear: 1927),
  const Author(id: 8, firstName: 'Антон', lastName: 'Чехов', country: 'Россия', birthYear: 1860),
];

final List<Book> seedBooks = [
  const Book(id: 1, title: 'Война и мир', isbn: '978-5-389-06256-6', year: 1869, pages: 1225, publisherId: 1, authorIds: [1], genreIds: [1, 2], copiesTotal: 5, copiesAvailable: 3),
  const Book(id: 2, title: 'Анна Каренина', isbn: '978-5-17-090635-2', year: 1877, pages: 864, publisherId: 1, authorIds: [1], genreIds: [1], copiesTotal: 4, copiesAvailable: 2),
  const Book(id: 3, title: 'Преступление и наказание', isbn: '978-5-389-07446-0', year: 1866, pages: 672, publisherId: 2, authorIds: [2], genreIds: [1, 3], copiesTotal: 7, copiesAvailable: 5),
  const Book(id: 4, title: '1984', isbn: '978-5-17-080115-2', year: 1949, pages: 320, publisherId: 3, authorIds: [3], genreIds: [4, 5], copiesTotal: 10, copiesAvailable: 8),
  const Book(id: 5, title: 'Мастер и Маргарита', isbn: '978-5-389-01686-6', year: 1967, pages: 512, publisherId: 1, authorIds: [4], genreIds: [1, 7], copiesTotal: 9, copiesAvailable: 7),
  const Book(id: 6, title: '451 градус по Фаренгейту', isbn: '978-5-17-077750-1', year: 1953, pages: 256, publisherId: 3, authorIds: [5], genreIds: [4, 5], copiesTotal: 12, copiesAvailable: 9),
];

final List<Reader> seedReaders = [
  Reader(
    id: 1,
    fullName: 'Иванов Иван Иванович',
    email: 'ivanov@mail.ru',
    phone: '+7 (999) 111-22-33',
    card: LibraryCard(cardNumber: 'LC-1001', issuedAt: DateTime(2025, 1, 15), isActive: true),
  ),
  Reader(
    id: 2,
    fullName: 'Петрова Анна Сергеевна',
    email: 'petrova@yandex.ru',
    phone: '+7 (999) 444-55-66',
    card: LibraryCard(cardNumber: 'LC-1002', issuedAt: DateTime(2025, 2, 20), isActive: true),
  ),
];

final Map<int, String> genreMap = {for (var g in seedGenres) g.id: g.name};
final Map<int, String> publisherMap = {for (var p in seedPublishers) p.id: p.name};