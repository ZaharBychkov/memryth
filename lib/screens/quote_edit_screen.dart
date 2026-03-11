import 'dart:math';

import 'package:flutter/material.dart';

import '../models/quote.dart';
import '../models/tag.dart';
import '../repositories/quote_repository.dart';
import '../repositories/tag_repository.dart';
import '../settings/app_settings_scope.dart';
import '../settings/app_strings.dart';

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
  late DateTime _createdAt;
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
      _createdAt = quote.createdAt;
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
      _createdAt = DateTime.now();
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
    final strings = AppStrings(AppSettingsScope.of(context).settings.language);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? const Color(0xFF262B33) : Colors.white;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Theme.of(context).dividerColor, width: 1.5),
    );

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final canLeave = await _handleBackNavigation(strings);
        if (!mounted || !canLeave) return;
        Navigator.of(this.context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final canLeave = await _handleBackNavigation(strings);
              if (!mounted || !canLeave) return;
              Navigator.of(this.context).pop();
            },
          ),
          title: Text(_isEditing ? strings.editTitle : strings.createTitle),
          actions: [
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4A6FA5),
                foregroundColor: Colors.white,
              ),
              child: Text(_isEditing ? strings.save : strings.add),
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
                Text(
                  strings.typeEntry,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
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
                        label: Text(strings.quoteTypeLabel(type)),
                        selected: _selectedType == type,
                        onSelected: (_) => setState(() => _selectedType = type),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(strings.createdAt),
                  subtitle: Text(_formatDate(_createdAt)),
                  trailing: TextButton(
                    onPressed: _pickCreatedAt,
                    child: Text(strings.changeDate),
                  ),
                ),
                const SizedBox(height: 4),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(strings.addToFavorites),
                  subtitle: Text(
                    strings.favoriteHint,
                    style: const TextStyle(fontSize: 13),
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
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  decoration: _inputDecoration(
                    context: context,
                    border: border,
                    fillColor: fillColor,
                    labelText: _selectedType == QuoteType.thought
                        ? strings.entryTextThought
                        : strings.entryText,
                    hintText: _selectedType == QuoteType.excerpt
                        ? strings.hintExcerpt
                        : strings.hintEntry,
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _authorController,
                  decoration: _inputDecoration(
                    context: context,
                    border: border,
                    fillColor: fillColor,
                    labelText: _selectedType == QuoteType.thought
                        ? strings.authorOptional
                        : strings.author,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _sourceTitleController,
                  decoration: _inputDecoration(
                    context: context,
                    border: border,
                    fillColor: fillColor,
                    labelText: strings.source,
                    hintText: strings.sourceHint,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _sourceDetailsController,
                  decoration: _inputDecoration(
                    context: context,
                    border: border,
                    fillColor: fillColor,
                    labelText: strings.sourceDetails,
                    hintText: strings.sourceDetailsHint,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _noteController,
                  minLines: 3,
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
                  decoration: _inputDecoration(
                    context: context,
                    border: border,
                    fillColor: fillColor,
                    labelText: strings.note,
                    hintText: strings.noteHint,
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  strings.tags,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var index = 0; index < _draftTags.length; index++)
                      InputChip(
                        label: Text(_draftTags[index].name),
                        side: BorderSide(
                          color: Theme.of(context).dividerColor,
                          width: 1.2,
                        ),
                        backgroundColor: isDark
                            ? const Color(0xFF262B33)
                            : const Color(0xFFF5EEE7),
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
                        decoration: _inputDecoration(
                          context: context,
                          border: border,
                          fillColor: fillColor,
                          labelText: strings.newTag,
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
                        child: Text(strings.add),
                      ),
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

  InputDecoration _inputDecoration({
    required BuildContext context,
    required OutlineInputBorder border,
    required Color fillColor,
    required String labelText,
    String? hintText,
    bool alignLabelWithHint = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      labelStyle: TextStyle(
        color: isDark ? const Color(0xFFB8AEA2) : const Color(0xFF8B7E74),
      ),
      hintStyle: TextStyle(
        color: isDark ? const Color(0xFF8F867A) : const Color(0xFF8B7E74),
      ),
      fillColor: fillColor,
      filled: true,
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 1.6,
        ),
      ),
      alignLabelWithHint: alignLabelWithHint,
    );
  }

  bool get _hasUnsavedChanges => _buildFormSignature() != _initialSignature;

  Future<bool> _handleBackNavigation(AppStrings strings) async {
    if (!_hasUnsavedChanges) return true;

    final approved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(strings.exitWithoutSaving),
          content: Text(strings.changesLost),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(strings.stay),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB84A3A),
                foregroundColor: Colors.white,
              ),
              child: Text(strings.exit),
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
            createdAt: _createdAt,
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
            createdAt: _createdAt,
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
      _createdAt.toIso8601String(),
      _tagController.text.trim(),
      tagsSignature,
    ].join('§');
  }

  String _genId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final suffix = _random.nextInt(1 << 32);
    return '$now$suffix';
  }

  Future<void> _pickCreatedAt() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _createdAt,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _createdAt = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _createdAt.hour,
        _createdAt.minute,
      );
    });
  }

  String _formatDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}';
  }
}

class _DraftTag {
  _DraftTag({this.id, required this.name});

  final String? id;
  final String name;
}
