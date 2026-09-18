import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/api_exceptions.dart';
import '../data/seed_data.dart';
import '../models/author.dart';
import '../models/book.dart';
import '../models/genre.dart';
import '../models/publisher.dart';
import '../repositories/book_repository.dart';
import '../repositories/cached_dictionary_repository.dart';
import '../state/book_list_notifier.dart';
import '../utils/validators.dart';

class BookFormScreen extends StatefulWidget {
  final int? id;
  const BookFormScreen({super.key, this.id});

  bool get isEditing => id != null;

  @override
  State<BookFormScreen> createState() => _BookFormScreenState();
}

class _BookFormScreenState extends State<BookFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _isbnController;
  late TextEditingController _yearController;
  late TextEditingController _pagesController;
  late TextEditingController _copiesTotalController;
  late TextEditingController _copiesAvailableController;

  int? _publisherId;
  List<int> _authorIds = [];
  List<int> _genreIds = [];

  bool _isDirty = false;
  bool _saving = false;
  Map<String, String> _serverErrors = {};

  List<Publisher> _publishers = seedPublishers;
  List<Author> _authors = seedAuthors;
  List<Genre> _genres = seedGenres;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _isbnController = TextEditingController();
    _yearController = TextEditingController(text: '2024');
    _pagesController = TextEditingController(text: '300');
    _copiesTotalController = TextEditingController(text: '5');
    _copiesAvailableController = TextEditingController(text: '5');
    _publisherId = _publishers.isNotEmpty ? _publishers.first.id : 1;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDictionariesAndData();
    });
  }

  Future<void> _loadDictionariesAndData() async {
    final dictRepo = context.read<CachedDictionaryRepository>();
    final bookRepo = context.read<BookRepository>();

    final pubs = await dictRepo.getPublishers();
    final auths = await dictRepo.getAuthors();
    final gens = await dictRepo.getGenres();

    if (!mounted) return;

    setState(() {
      _publishers = pubs;
      _authors = auths;
      _genres = gens;
      if (_publisherId == null && _publishers.isNotEmpty) {
        _publisherId = _publishers.first.id;
      }
    });

    if (widget.isEditing) {
      final existing = await bookRepo.findById(widget.id!);
      if (!mounted) return;
      if (existing != null) {
        setState(() {
          _titleController.text = existing.title;
          _isbnController.text = existing.isbn;
          _yearController.text = '${existing.year}';
          _pagesController.text = '${existing.pages}';
          _copiesTotalController.text = '${existing.copiesTotal}';
          _copiesAvailableController.text = '${existing.copiesAvailable}';
          _publisherId = existing.publisherId;
          _authorIds = [...existing.authorIds];
          _genreIds = [...existing.genreIds];
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _isbnController.dispose();
    _yearController.dispose();
    _pagesController.dispose();
    _copiesTotalController.dispose();
    _copiesAvailableController.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  Future<bool> _confirmLeave() async {
    if (!_isDirty) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Несохраненные изменения'),
        content: const Text(
          'Вы уверены, что хотите покинуть форму? Все несохраненные данные будут потеряны.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Остаться')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Уйти')),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _submit() async {
    setState(() => _serverErrors = {});
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    final bookRepo = context.read<BookRepository>();
    final bookNotifier = context.read<BookListNotifier>();
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    final book = Book(
      id: widget.id ?? 0,
      title: _titleController.text.trim(),
      isbn: _isbnController.text.trim(),
      year: int.parse(_yearController.text.trim()),
      pages: int.parse(_pagesController.text.trim()),
      publisherId: _publisherId ?? 1,
      authorIds: _authorIds,
      genreIds: _genreIds,
      copiesTotal: int.parse(_copiesTotalController.text.trim()),
      copiesAvailable: int.parse(_copiesAvailableController.text.trim()),
    );

    try {
      if (widget.isEditing) {
        await bookRepo.update(book);
      } else {
        await bookRepo.create(book);
      }

      await bookNotifier.load();

      if (!mounted) return;

      _isDirty = false;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing
                ? 'Книга успешно обновлена'
                : 'Книга успешно добавлена на сервере',
          ),
        ),
      );
      router.go('/books');
    } on ValidationException catch (e) {
      if (!mounted) return;
      setState(() => _serverErrors = e.errors);
      _formKey.currentState?.validate();
    } on ConflictException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.orange),
      );
    } on ApiException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = GoRouter.of(context);

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldLeave = await _confirmLeave();
        if (shouldLeave && mounted) {
          router.go('/books');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isEditing
              ? 'Редактирование книги'
              : 'Новая книга (Сервер)'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final shouldLeave = await _confirmLeave();
              if (shouldLeave && mounted) {
                router.go('/books');
              }
            },
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    onChanged: _markDirty,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            labelText: 'Название книги *',
                            border: const OutlineInputBorder(),
                            errorText: _serverErrors['title'],
                          ),
                          validator: (v) =>
                              AppValidators.requiredField(v) ??
                              AppValidators.minLength(v, 2),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _isbnController,
                          decoration: InputDecoration(
                            labelText: 'ISBN *',
                            border: const OutlineInputBorder(),
                            errorText: _serverErrors['isbn'],
                          ),
                          validator: AppValidators.isbn,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _yearController,
                                decoration: const InputDecoration(
                                  labelText: 'Год издания *',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (v) =>
                                    AppValidators.intRange(v, 1500, 2026),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _pagesController,
                                decoration: const InputDecoration(
                                  labelText: 'Кол-во страниц *',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                validator: AppValidators.positiveInt,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<int>(
                          value: _publisherId,
                          decoration: const InputDecoration(
                            labelText: 'Издательство (Многие к одному) *',
                            border: OutlineInputBorder(),
                          ),
                          items: _publishers
                              .map((p) => DropdownMenuItem(
                                  value: p.id, child: Text(p.name)))
                              .toList(),
                          onChanged: (val) {
                            setState(() => _publisherId = val);
                            _markDirty();
                          },
                          validator: (v) =>
                              v == null ? 'Выберите издательство' : null,
                        ),
                        const SizedBox(height: 16),
                        FormField<List<int>>(
                          initialValue: _authorIds,
                          validator: (v) => (_authorIds.isEmpty)
                              ? 'Выберите хотя бы одного автора'
                              : null,
                          builder: (state) {
                            return InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Авторы (Многие ко многим) *',
                                border: const OutlineInputBorder(),
                                errorText: state.errorText,
                              ),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _authors.map((a) {
                                  final selected = _authorIds.contains(a.id);
                                  return FilterChip(
                                    label: Text(a.fullName),
                                    selected: selected,
                                    onSelected: (val) {
                                      setState(() {
                                        val
                                            ? _authorIds.add(a.id)
                                            : _authorIds.remove(a.id);
                                      });
                                      state.didChange(_authorIds);
                                      _markDirty();
                                    },
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        FormField<List<int>>(
                          initialValue: _genreIds,
                          validator: (v) => (_genreIds.isEmpty)
                              ? 'Выберите хотя бы один жанр'
                              : null,
                          builder: (state) {
                            return InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Жанры (Многие ко многим) *',
                                border: const OutlineInputBorder(),
                                errorText: state.errorText,
                              ),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _genres.map((g) {
                                  final selected = _genreIds.contains(g.id);
                                  return FilterChip(
                                    label: Text(g.name),
                                    selected: selected,
                                    onSelected: (val) {
                                      setState(() {
                                        val
                                            ? _genreIds.add(g.id)
                                            : _genreIds.remove(g.id);
                                      });
                                      state.didChange(_genreIds);
                                      _markDirty();
                                    },
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _copiesTotalController,
                                decoration: const InputDecoration(
                                  labelText: 'Всего экз. *',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                validator: AppValidators.positiveInt,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _copiesAvailableController,
                                decoration: const InputDecoration(
                                  labelText: 'В наличии *',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (v) => AppValidators.intRange(
                                  v,
                                  0,
                                  int.tryParse(_copiesTotalController.text) ??
                                      9999,
                                  'Не может превышать общее число',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          icon: _saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.save),
                          label: Text(_saving
                              ? 'Сохранение...'
                              : (widget.isEditing
                                  ? 'Сохранить'
                                  : 'Создать книгу')),
                          style: FilledButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16)),
                          onPressed: _saving ? null : _submit,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
