import 'package:flutter/material.dart';

import '../models/quote.dart';
import '../models/tag.dart';
import '../repositories/quote_repository.dart';
import '../repositories/tag_repository.dart';
import '../settings/app_settings_scope.dart';
import '../settings/app_strings.dart';
import '../widgets/tag_chip.dart';
import 'quote_edit_screen.dart';

class QuoteDetailScreen extends StatefulWidget {
  const QuoteDetailScreen({
    super.key,
    required this.quote,
    required this.tags,
    required this.quoteRepository,
    required this.tagRepository,
  });

  final Quote quote;
  final List<Tag> tags;
  final QuoteRepository quoteRepository;
  final TagRepository tagRepository;

  @override
  State<QuoteDetailScreen> createState() => _QuoteDetailScreenState();
}

class _QuoteDetailScreenState extends State<QuoteDetailScreen> {
  late Quote _quote = widget.quote;
  late List<Tag> _tags = widget.tags;

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context).settings;
    final strings = AppStrings(settings.language);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final quoteStyle = TextStyle(
      color: Theme.of(context).textTheme.bodyLarge?.color,
      fontSize: settings.quoteTextSize.fontSize + 3,
      height: settings.quoteLineSpacing.height,
      fontWeight: FontWeight.w600,
    );

    final metaItems = <String>[];
    if (_quote.author.trim().isNotEmpty) {
      metaItems.add(_quote.author.trim());
    }
    if (_quote.sourceTitle.trim().isNotEmpty) {
      metaItems.add(_quote.sourceTitle.trim());
    }
    if (_quote.sourceDetails.trim().isNotEmpty) {
      metaItems.add(_quote.sourceDetails.trim());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.quoteTypeLabel(_quote.type)),
        actions: [
          IconButton(
            onPressed: _toggleFavorite,
            icon: Icon(
              _quote.isFavorite
                  ? Icons.star_rounded
                  : Icons.star_border_rounded,
              color: _quote.isFavorite
                  ? const Color(0xFFE4A11B)
                  : (isDark
                        ? const Color(0xFFB8AEA2)
                        : const Color(0xFF8B7E74)),
            ),
          ),
          IconButton(
            onPressed: _openEdit,
            icon: const Icon(Icons.edit_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailChip(
                type: _quote.type,
                label: strings.quoteTypeLabel(_quote.type),
              ),
              const SizedBox(height: 18),
              SelectableText(_quote.text.trim(), style: quoteStyle),
              if (metaItems.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(
                  metaItems.join(' • '),
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFFB8AEA2)
                        : const Color(0xFF8B7E74),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              _MetaSection(
                title: strings.createdAt,
                value: _formatDateTime(_quote.createdAt),
              ),
              const SizedBox(height: 10),
              _MetaSection(
                title: strings.updatedAt,
                value: _formatDateTime(_quote.updatedAt),
              ),
              if (_quote.note.trim().isNotEmpty) ...[
                const SizedBox(height: 22),
                Text(
                  strings.myNote,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF262B33)
                        : const Color(0xFFF6F4EF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: SelectableText(
                    _quote.note.trim(),
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 15,
                      height: settings.quoteLineSpacing.height,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 22),
              Text(
                strings.tags,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              if (_tags.isEmpty)
                Text(
                  strings.tagNone,
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFFB8AEA2)
                        : const Color(0xFF8B7E74),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final tag in _tags)
                      TagChip(
                        tagName: tag.name,
                        query: '',
                        selected: false,
                        onTap: () {},
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleFavorite() async {
    final updated = _quote.copyWith(
      isFavorite: !_quote.isFavorite,
      updatedAt: DateTime.now(),
    );
    await widget.quoteRepository.save(updated);
    if (!mounted) return;
    setState(() => _quote = updated);
  }

  Future<void> _openEdit() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => QuoteEditScreen(
          quoteRepository: widget.quoteRepository,
          tagRepository: widget.tagRepository,
          quote: _quote,
        ),
      ),
    );

    if (saved != true || !mounted) return;

    final quotes = widget.quoteRepository.getAll();
    Quote? refreshed;
    for (final quote in quotes) {
      if (quote.id == _quote.id) {
        refreshed = quote;
        break;
      }
    }
    if (refreshed != null) {
      final tagsById = {
        for (final tag in widget.tagRepository.getAll()) tag.id: tag,
      };
      setState(() {
        _quote = refreshed!;
        _tags = _quote.tagIds
            .map((id) => tagsById[id])
            .whereType<Tag>()
            .toList();
      });
    }
  }

  String _formatDateTime(DateTime value) {
    final date =
        '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}';
    final time =
        '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
    return '$date • $time';
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.type, required this.label});

  final QuoteType type;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = switch (type) {
      QuoteType.quote => const Color(0xFF395A8A),
      QuoteType.thought => const Color(0xFF6A4FA3),
      QuoteType.excerpt => const Color(0xFF3C7B5A),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MetaSection extends StatelessWidget {
  const _MetaSection({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        SizedBox(
          width: 92,
          child: Text(
            title,
            style: TextStyle(
              color: isDark ? const Color(0xFFB8AEA2) : const Color(0xFF8B7E74),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
