import 'dart:math';

import 'package:flutter/material.dart';

import '../models/quote.dart';
import '../models/tag.dart';
import '../repositories/quote_repository.dart';
import '../repositories/tag_repository.dart';

class QuoteEditScreen extends StatefulWidget {
  const QuoteEditScreen({
    super.key,
    required this.quoteRepository,
    required this.tagRepository,
    this.quote,
  });

  final QuoteRepository quoteRepository;
  final TagRepository tagRepository;
  final Quote? quote;

  @override
  State<QuoteEditScreen> createState() => _QuoteEditScreenState();
}

class _QuoteEditScreenState extends State<QuoteEditScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _sourceTitleController = TextEditingController();
  final TextEditingController _sourceDetailsController =
      TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  final List<_DraftTag> _draftTags = <_DraftTag>[];
  final Random _random = Random();

  late final String _initialSignature;
  late QuoteType _selectedType;
  bool _isFavorite = false;

  bool get _isEditing => widget.quote != null;

  @override
  void initState() {
    super.initState();
    final quote = widget.quote;
    if (quote != null) {
      _textController.text = quote.text;
      _authorController.text = quote.author;
      _sourceTitleController.text = quote.sourceTitle;
      _sourceDetailsController.text = quote.sourceDetails;
      _noteController.text = quote.note;
      _selectedType = quote.type;
      _isFavorite = quote.isFavorite;

      final tagsById = {
        for (final tag in widget.tagRepository.getAll()) tag.id: tag,
      };
      for (final tagId in quote.tagIds) {
        final tag = tagsById[tagId];
        if (tag != null) {
          _draftTags.add(_DraftTag(id: tag.id, name: tag.name));
        }
      }
    } else {
      _selectedType = QuoteType.quote;
    }

    _initialSignature = _buildFormSignature();
  }

  @override
  void dispose() {
    _textController.dispose();
    _authorController.dispose();
    _sourceTitleController.dispose();
    _sourceDetailsController.dispose();
    _noteController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFD8CEC5), width: 1.5),
    );

    final allTags = widget.tagRepository.getAll().toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final canLeave = await _handleBackNavigation();
        if (!mounted || !canLeave) return;
        Navigator.of(this.context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final canLeave = await _handleBackNavigation();
              if (!mounted || !canLeave) return;
              Navigator.of(this.context).pop();
            },
          ),
          title: Text(_isEditing ? 'Редактирование' : 'Новая запись'),
          actions: [
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4A6FA5),
                foregroundColor: Colors.white,
              ),
              child: Text(_isEditing ? 'Сохранить' : 'Добавить'),
            ),
            const SizedBox(width: 12),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Тип записи',
                  style: TextStyle(
                    color: Color(0xFF2C2C2C),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final type in QuoteType.values)
                      ChoiceChip(
                        label: Text(type.label),
                        selected: _selectedType == type,
                        onSelected: (_) => setState(() => _selectedType = type),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('В избранное'),
                  subtitle: const Text(
                    'Быстрый доступ к самым важным записям',
                    style: TextStyle(fontSize: 13),
                  ),
                  value: _isFavorite,
                  activeThumbColor: const Color(0xFFE4A11B),
                  onChanged: (value) => setState(() => _isFavorite = value),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _textController,
                  minLines: 6,
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    labelText: _selectedType == QuoteType.thought
                        ? 'Текст мысли'
                        : 'Текст записи',
                    hintText: _selectedType == QuoteType.excerpt
                        ? 'Вставь фрагмент текста полностью'
                        : 'Сохрани текст, к которому хочешь вернуться',
                    labelStyle: const TextStyle(color: Color(0xFF8B7E74)),
                    fillColor: Colors.white,
                    filled: true,
                    border: border,
                    enabledBorder: border,
                    focusedBorder: border,
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _authorController,
                  decoration: InputDecoration(
                    labelText: _selectedType == QuoteType.thought
                        ? 'Автор / собеседник (необязательно)'
                        : 'Автор',
                    labelStyle: const TextStyle(color: Color(0xFF8B7E74)),
                    fillColor: Colors.white,
                    filled: true,
                    border: border,
                    enabledBorder: border,
                    focusedBorder: border,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _sourceTitleController,
                  decoration: InputDecoration(
                    labelText: 'Источник',
                    hintText: 'Книга, статья, видео, лекция',
                    labelStyle: const TextStyle(color: Color(0xFF8B7E74)),
                    fillColor: Colors.white,
                    filled: true,
                    border: border,
                    enabledBorder: border,
                    focusedBorder: border,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _sourceDetailsController,
                  decoration: InputDecoration(
                    labelText: 'Детали источника',
                    hintText: 'Глава, страница, таймкод',
                    labelStyle: const TextStyle(color: Color(0xFF8B7E74)),
                    fillColor: Colors.white,
                    filled: true,
                    border: border,
                    enabledBorder: border,
                    focusedBorder: border,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _noteController,
                  minLines: 3,
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    labelText: 'Моя заметка',
                    hintText:
                        'Почему ты сохранил эту запись и как хочешь её использовать',
                    labelStyle: const TextStyle(color: Color(0xFF8B7E74)),
                    fillColor: Colors.white,
                    filled: true,
                    border: border,
                    enabledBorder: border,
                    focusedBorder: border,
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),
                Text('Теги', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var index = 0; index < _draftTags.length; index++)
                      InputChip(
                        label: Text(_draftTags[index].name),
                        side: const BorderSide(
                          color: Color(0xFFD8CEC5),
                          width: 1.2,
                        ),
                        backgroundColor: const Color(0xFFF5EEE7),
                        onDeleted: () =>
                            setState(() => _draftTags.removeAt(index)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _tagController,
                        onSubmitted: (_) => _addTag(),
                        decoration: InputDecoration(
                          labelText: 'Новый тег',
                          labelStyle: const TextStyle(color: Color(0xFF8B7E74)),
                          fillColor: Colors.white,
                          filled: true,
                          border: border,
                          enabledBorder: border,
                          focusedBorder: border,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 56,
                      child: FilledButton(
                        onPressed: _addTag,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF4A6FA5),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Добавить'),
                      ),
                    ),
                  ],
                ),
                if (allTags.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text(
                    'Быстро добавить из существующих',
                    style: TextStyle(
                      color: Color(0xFF8B7E74),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final tag in allTags)
                        FilterChip(
                          label: Text(tag.name),
                          selected: _draftTags.any((item) => item.id == tag.id),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _ensureTagAdded(
                                  _DraftTag(id: tag.id, name: tag.name),
                                );
                              } else {
                                _draftTags.removeWhere(
                                  (item) => item.id == tag.id,
                                );
                              }
                            });
                          },
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool get _hasUnsavedChanges => _buildFormSignature() != _initialSignature;

  Future<bool> _handleBackNavigation() async {
    if (!_hasUnsavedChanges) return true;

    final approved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Выйти без сохранения?'),
          content: const Text('Все несохранённые изменения будут потеряны.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Остаться'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB84A3A),
                foregroundColor: Colors.white,
              ),
              child: const Text('Выйти'),
            ),
          ],
        );
      },
    );

    return approved == true;
  }

  void _addTag() {
    final raw = _tagController.text.trim();
    if (raw.isEmpty) return;

    setState(() {
      _ensureTagAdded(_DraftTag(name: raw));
      _tagController.clear();
    });
  }

  void _ensureTagAdded(_DraftTag draft) {
    final normalized = draft.name.trim().toLowerCase();
    final alreadyExists = _draftTags.any(
      (item) => item.name.trim().toLowerCase() == normalized,
    );
    if (!alreadyExists) {
      _draftTags.add(draft);
    }
  }

  Future<void> _save() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final author = _authorController.text.trim();
    final sourceTitle = _sourceTitleController.text.trim();
    final sourceDetails = _sourceDetailsController.text.trim();
    final note = _noteController.text.trim();

    final existingTags = {
      for (final tag in widget.tagRepository.getAll())
        tag.name.trim().toLowerCase(): tag,
    };
    final tagIds = <String>[];

    for (final draft in _draftTags) {
      if (draft.id != null) {
        tagIds.add(draft.id!);
        continue;
      }

      final normalized = draft.name.trim().toLowerCase();
      final existing = existingTags[normalized];
      if (existing != null) {
        tagIds.add(existing.id);
        continue;
      }

      final id = _genId();
      final tag = Tag(id: id, name: draft.name.trim());
      await widget.tagRepository.save(tag);
      existingTags[normalized] = tag;
      tagIds.add(id);
    }

    final now = DateTime.now();
    final original = widget.quote;
    final quote = original == null
        ? Quote(
            id: _genId(),
            text: text,
            author: author,
            tagIds: tagIds,
            typeKey: _selectedType.key,
            createdAt: now,
            updatedAt: now,
            isFavorite: _isFavorite,
            sourceTitle: sourceTitle,
            sourceDetails: sourceDetails,
            note: note,
          )
        : original.copyWith(
            text: text,
            author: author,
            tagIds: tagIds,
            typeKey: _selectedType.key,
            updatedAt: now,
            isFavorite: _isFavorite,
            sourceTitle: sourceTitle,
            sourceDetails: sourceDetails,
            note: note,
          );

    await widget.quoteRepository.save(quote);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  String _buildFormSignature() {
    final tagsSignature = _draftTags
        .map((tag) => '${tag.id ?? ''}::${tag.name.trim().toLowerCase()}')
        .join('||');

    return [
      _selectedType.key,
      _isFavorite.toString(),
      _textController.text.trim(),
      _authorController.text.trim(),
      _sourceTitleController.text.trim(),
      _sourceDetailsController.text.trim(),
      _noteController.text.trim(),
      _tagController.text.trim(),
      tagsSignature,
    ].join('§');
  }

  String _genId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final suffix = _random.nextInt(1 << 32);
    return '$now$suffix';
  }
}

class _DraftTag {
  _DraftTag({this.id, required this.name});

  final String? id;
  final String name;
}
