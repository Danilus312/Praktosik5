import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/library_card.dart';
import '../models/reader.dart';
import '../repositories/app_repositories.dart';
import '../utils/validators.dart';

class ReaderFormScreen extends StatefulWidget {
  final int? id;
  const ReaderFormScreen({super.key, this.id});

  bool get isEditing => id != null;

  @override
  State<ReaderFormScreen> createState() => _ReaderFormScreenState();
}

class _ReaderFormScreenState extends State<ReaderFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _cardNumberController;
  bool _cardIsActive = true;

  bool _isDirty = false;
  String? _emailCustomError;

  @override
  void initState() {
    super.initState();
    final repo = context.read<PersistentLibraryRepository>();
    Reader? existing;
    if (widget.isEditing) {
      existing = repo.readers.cast<Reader?>().firstWhere(
            (r) => r?.id == widget.id,
            orElse: () => null,
          );
    }

    _fullNameController = TextEditingController(text: existing?.fullName ?? '');
    _emailController = TextEditingController(text: existing?.email ?? '');
    _phoneController =
        TextEditingController(text: existing?.phone ?? '+7 (999) ');
    _cardNumberController = TextEditingController(
      text: existing?.card.cardNumber ??
          'LC-${DateTime.now().millisecondsSinceEpoch % 10000}',
    );
    _cardIsActive = existing?.card.isActive ?? true;
  }

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  Future<void> _submit() async {
    setState(() => _emailCustomError = null);
    final repo = context.read<PersistentLibraryRepository>();

    final emailVal = _emailController.text.trim();
    if (!repo.isEmailUnique(emailVal, widget.id)) {
      setState(
          () => _emailCustomError = 'Читатель с таким email уже существует');
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final reader = Reader(
      id: widget.id ?? 0,
      fullName: _fullNameController.text.trim(),
      email: emailVal,
      phone: _phoneController.text.trim(),
      card: LibraryCard(
        cardNumber: _cardNumberController.text.trim(),
        issuedAt: DateTime.now(),
        isActive: _cardIsActive,
      ),
    );

    await repo.saveReader(reader);
    if (!mounted) return;
    _isDirty = false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(widget.isEditing
              ? 'Данные читателя обновлены'
              : 'Читатель зарегистрирован')),
    );
    context.go('/readers');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.isEditing ? 'Редактирование читателя' : 'Новый читатель'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/readers'),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
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
                        controller: _fullNameController,
                        decoration: const InputDecoration(
                            labelText: 'ФИО читателя *',
                            border: OutlineInputBorder()),
                        validator: (v) =>
                            AppValidators.requiredField(v) ??
                            AppValidators.minLength(v, 3),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Электронная почта *',
                          border: const OutlineInputBorder(),
                          errorText: _emailCustomError,
                        ),
                        validator: AppValidators.email,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                            labelText: 'Телефон *',
                            border: OutlineInputBorder()),
                        validator: AppValidators.requiredField,
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color:
                                  Theme.of(context).colorScheme.outlineVariant),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Читательский билет (Связь 1:1)',
                                style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _cardNumberController,
                              decoration: const InputDecoration(
                                  labelText: 'Номер билета *',
                                  border: OutlineInputBorder()),
                              validator: AppValidators.requiredField,
                            ),
                            const SizedBox(height: 12),
                            SwitchListTile(
                              title: const Text('Билет активен'),
                              value: _cardIsActive,
                              onChanged: (val) {
                                setState(() => _cardIsActive = val);
                                _markDirty();
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        icon: const Icon(Icons.save),
                        label: Text(widget.isEditing
                            ? 'Сохранить'
                            : 'Зарегистрировать читателя'),
                        style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16)),
                        onPressed: _submit,
                      ),
                    ],
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
