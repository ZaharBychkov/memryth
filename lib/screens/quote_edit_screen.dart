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
  final TextEditingController _tagController = TextEditingController();
  final List<_DraftTag> _draftTags = <_DraftTag>[];
  final Random _random = Random();

  late final String _initialText;
  late final String _initialAuthor;
  late final String _initialTagsSignature;

  bool get _isEditing => widget.quote != null;

  @override
  void initState() {
    super.initState();
    final quote = widget.quote;
    if (quote != null) {
      _textController.text = quote.text;
      _authorController.text = quote.author;

      final tagsById = {
        for (final tag in widget.tagRepository.getAll()) tag.id: tag,
      };
      for (final tagId in quote.tagIds) {
        final tag = tagsById[tagId];
        if (tag != null) {
          _draftTags.add(_DraftTag(id: tag.id, name: tag.name));
        }
      }
    }

    _initialText = _textController.text.trim();
    _initialAuthor = _authorController.text.trim();
    _initialTagsSignature = _buildTagsSignature();
  }

  @override
  void dispose() {
    _textController.dispose();
    _authorController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFD8CEC5), width: 1.5),
    );

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
          title: Text(
            _isEditing
                ? '\u0420\u0435\u0434\u0430\u043a\u0442\u0438\u0440\u043e\u0432\u0430\u043d\u0438\u0435'
                : '\u041d\u043e\u0432\u0430\u044f \u0446\u0438\u0442\u0430\u0442\u0430',
          ),
          actions: [
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4A6FA5),
                foregroundColor: Colors.white,
              ),
              child: Text(
                _isEditing
                    ? '\u0420\u0435\u0434\u0430\u043a\u0442\u0438\u0440\u043e\u0432\u0430\u0442\u044c'
                    : '\u0421\u043e\u0445\u0440\u0430\u043d\u0438\u0442\u044c',
              ),
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
                TextField(
                  controller: _textController,
                  minLines: 6,
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    labelText:
                        '\u0422\u0435\u043a\u0441\u0442 \u0446\u0438\u0442\u0430\u0442\u044b',
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
                    labelText: '\u0410\u0432\u0442\u043e\u0440',
                    labelStyle: const TextStyle(color: Color(0xFF8B7E74)),
                    fillColor: Colors.white,
                    filled: true,
                    border: border,
                    enabledBorder: border,
                    focusedBorder: border,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '\u0422\u0435\u0433\u0438',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < _draftTags.length; i++)
                      InputChip(
                        label: Text(_draftTags[i].name),
                        side: const BorderSide(color: Color(0xFFD8CEC5), width: 1.2),
                        backgroundColor: const Color(0xFFF5EEE7),
                        onDeleted: () => setState(() => _draftTags.removeAt(i)),
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
                        decoration: InputDecoration(
                          labelText:
                              '\u041d\u043e\u0432\u044b\u0439 \u0442\u0435\u0433',
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
                        child: const Text(
                          '\u0414\u043e\u0431\u0430\u0432\u0438\u0442\u044c',
                        ),
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

  bool get _hasUnsavedChanges {
    if (_textController.text.trim() != _initialText) return true;
    if (_authorController.text.trim() != _initialAuthor) return true;
    if (_buildTagsSignature() != _initialTagsSignature) return true;
    if (_tagController.text.trim().isNotEmpty) return true;
    return false;
  }

  Future<bool> _handleBackNavigation() async {
    if (!_hasUnsavedChanges) return true;

    final approved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            '\u0412\u044b\u0439\u0442\u0438 \u0431\u0435\u0437 \u0441\u043e\u0445\u0440\u0430\u043d\u0435\u043d\u0438\u044f?',
          ),
          content: const Text(
            '\u0412\u043d\u0435\u0441\u0435\u043d\u043d\u044b\u0435 \u0438\u0437\u043c\u0435\u043d\u0435\u043d\u0438\u044f \u0431\u0443\u0434\u0443\u0442 \u043f\u043e\u0442\u0435\u0440\u044f\u043d\u044b.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                '\u041e\u0441\u0442\u0430\u0442\u044c\u0441\u044f',
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB84A3A),
                foregroundColor: Colors.white,
              ),
              child: const Text('\u0412\u044b\u0439\u0442\u0438'),
            ),
          ],
        );
      },
    );

    return approved == true;
  }

  void _addTag() {
    final raw = _tagController.text;
    if (raw.trim().isEmpty) return;
    setState(() {
      _draftTags.add(_DraftTag(name: raw));
      _tagController.clear();
    });
  }

  Future<void> _save() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final author = _authorController.text.trim();
    final tagIds = <String>[];

    for (final draft in _draftTags) {
      if (draft.id != null) {
        tagIds.add(draft.id!);
        continue;
      }

      final id = _genId();
      final tag = Tag(id: id, name: draft.name);
      await widget.tagRepository.save(tag);
      tagIds.add(id);
    }

    final original = widget.quote;
    final quote = original == null
        ? Quote(
            id: _genId(),
            text: text,
            author: author,
            tagIds: tagIds,
          )
        : original.copyWith(
            text: text,
            author: author,
            tagIds: tagIds,
          );

    await widget.quoteRepository.save(quote);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  String _buildTagsSignature() {
    return _draftTags
        .map((tag) => '${tag.id ?? ''}::${tag.name.trim()}')
        .join('||');
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
