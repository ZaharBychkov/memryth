import 'dart:math';

import 'package:flutter/material.dart';

import '../models/quote.dart';
import '../models/tag.dart';
import '../repositories/quote_repository.dart';
import '../repositories/tag_repository.dart';

class QuoteEditViewModel extends ChangeNotifier {
  QuoteEditViewModel({
    required QuoteRepository quoteRepository,
    required TagRepository tagRepository,
    Quote? quote,
  }) : _quoteRepository = quoteRepository,
       _tagRepository = tagRepository,
       _quote = quote {
    if (quote != null) {
      textController.text = quote.text;
      authorController.text = quote.author;
      sourceTitleController.text = quote.sourceTitle;
      sourceDetailsController.text = quote.sourceDetails;
      noteController.text = quote.note;
      _selectedType = quote.type;
      _createdAt = quote.createdAt;
      _isFavorite = quote.isFavorite;

      final tagsById = {for (final tag in _tagRepository.getAll()) tag.id: tag};
      for (final tagId in quote.tagIds) {
        final tag = tagsById[tagId];
        if (tag != null) {
          _draftTags.add(DraftTag(id: tag.id, name: tag.name));
        }
      }
    } else {
      _selectedType = QuoteType.quote;
      _createdAt = DateTime.now();
    }

    _initialSignature = buildFormSignature();
  }

  final QuoteRepository _quoteRepository;
  final TagRepository _tagRepository;
  final Quote? _quote;
  final Random _random = Random();

  final textController = TextEditingController();
  final authorController = TextEditingController();
  final sourceTitleController = TextEditingController();
  final sourceDetailsController = TextEditingController();
  final noteController = TextEditingController();
  final tagController = TextEditingController();

  final List<DraftTag> _draftTags = <DraftTag>[];
  late final String _initialSignature;
  late QuoteType _selectedType;
  late DateTime _createdAt;
  bool _isFavorite = false;

  bool get isEditing => _quote != null;
  QuoteType get selectedType => _selectedType;
  DateTime get createdAt => _createdAt;
  bool get isFavorite => _isFavorite;
  List<DraftTag> get draftTags => List.unmodifiable(_draftTags);
  bool get hasUnsavedChanges => buildFormSignature() != _initialSignature;

  void setSelectedType(QuoteType value) {
    if (_selectedType == value) return;
    _selectedType = value;
    notifyListeners();
  }

  void setFavorite(bool value) {
    if (_isFavorite == value) return;
    _isFavorite = value;
    notifyListeners();
  }

  void setCreatedAt(DateTime value) {
    _createdAt = DateTime(
      value.year,
      value.month,
      value.day,
      _createdAt.hour,
      _createdAt.minute,
    );
    notifyListeners();
  }

  void addTagFromInput() {
    final raw = tagController.text.trim();
    if (raw.isEmpty) return;
    _ensureTagAdded(DraftTag(name: raw));
    tagController.clear();
    notifyListeners();
  }

  void removeTagAt(int index) {
    _draftTags.removeAt(index);
    notifyListeners();
  }

  Future<bool> save() async {
    final text = textController.text.trim();
    if (text.isEmpty) return false;

    final author = authorController.text.trim();
    final sourceTitle = sourceTitleController.text.trim();
    final sourceDetails = sourceDetailsController.text.trim();
    final note = noteController.text.trim();

    final existingTags = {
      for (final tag in _tagRepository.getAll()) tag.name.trim().toLowerCase(): tag,
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
      await _tagRepository.save(tag);
      existingTags[normalized] = tag;
      tagIds.add(id);
    }

    final now = DateTime.now();
    final quote = _quote == null
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
        : _quote.copyWith(
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

    await _quoteRepository.save(quote);
    return true;
  }

  String buildFormSignature() {
    final tagsSignature = _draftTags
        .map((tag) => '${tag.id ?? ''}::${tag.name.trim().toLowerCase()}')
        .join('||');

    return [
      _selectedType.key,
      _isFavorite.toString(),
      textController.text.trim(),
      authorController.text.trim(),
      sourceTitleController.text.trim(),
      sourceDetailsController.text.trim(),
      noteController.text.trim(),
      _createdAt.toIso8601String(),
      tagController.text.trim(),
      tagsSignature,
    ].join('В§');
  }

  void _ensureTagAdded(DraftTag draft) {
    final normalized = draft.name.trim().toLowerCase();
    final alreadyExists = _draftTags.any(
      (item) => item.name.trim().toLowerCase() == normalized,
    );
    if (!alreadyExists) {
      _draftTags.add(draft);
    }
  }

  String _genId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final suffix = _random.nextInt(1 << 32);
    return '$now$suffix';
  }

  @override
  void dispose() {
    textController.dispose();
    authorController.dispose();
    sourceTitleController.dispose();
    sourceDetailsController.dispose();
    noteController.dispose();
    tagController.dispose();
    super.dispose();
  }
}

class DraftTag {
  DraftTag({this.id, required this.name});

  final String? id;
  final String name;
}
