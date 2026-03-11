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
  bool _detailsExpanded = false;

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

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.quoteTypeLabel(_quote.type)),
        actions: [
          IconButton(
            onPressed: _toggleFavorite,
            icon: Icon(
              _quote.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
              color: _quote.isFavorite
                  ? const Color(0xFFE4A11B)
                  : (isDark ? const Color(0xFFB8AEA2) : const Color(0xFF8B7E74)),
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
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(_quote.text.trim(), style: quoteStyle),
              if (_quote.author.trim().isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(
                  _quote.author.trim(),
                  style: TextStyle(
                    color: isDark ? const Color(0xFFB8AEA2) : const Color(0xFF8B7E74),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Center(
                child: InkWell(
                  onTap: () => setState(() => _detailsExpanded = !_detailsExpanded),
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Column(
                      children: [
                        Text(
                          strings.details,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Icon(
                          _detailsExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 220),
                crossFadeState: _detailsExpanded
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                firstChild: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _DetailsBlock(
                    quote: _quote,
                    tags: _tags,
                    strings: strings,
                    onChangeDate: _pickCreatedAt,
                  ),
                ),
                secondChild: const SizedBox.shrink(),
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

  Future<void> _pickCreatedAt() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _quote.createdAt,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;

    final updated = _quote.copyWith(
      createdAt: DateTime(
        picked.year,
        picked.month,
        picked.day,
        _quote.createdAt.hour,
        _quote.createdAt.minute,
      ),
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
        _tags = _quote.tagIds.map((id) => tagsById[id]).whereType<Tag>().toList();
      });
    }
  }
}

class _DetailsBlock extends StatelessWidget {
  const _DetailsBlock({
    required this.quote,
    required this.tags,
    required this.strings,
    required this.onChangeDate,
  });

  final Quote quote;
  final List<Tag> tags;
  final AppStrings strings;
  final VoidCallback onChangeDate;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF232830) : const Color(0xFFF6F4EF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (quote.sourceTitle.trim().isNotEmpty)
            _InfoLine(title: strings.source, value: quote.sourceTitle.trim()),
          if (quote.sourceDetails.trim().isNotEmpty)
            _InfoLine(
              title: strings.sourceDetails,
              value: quote.sourceDetails.trim(),
              topSpacing: 10,
            ),
          if (quote.note.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              strings.myNote,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            SelectableText(
              quote.note.trim(),
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            strings.tags,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (tags.isEmpty)
            Text(
              strings.tagNone,
              style: TextStyle(
                color: isDark ? const Color(0xFFB8AEA2) : const Color(0xFF8B7E74),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in tags)
                  TagChip(
                    tagName: tag.name,
                    query: '',
                    selected: false,
                    onTap: () {},
                  ),
              ],
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _InfoLine(
                  title: strings.createdAt,
                  value: _formatDate(quote.createdAt),
                ),
              ),
              TextButton(
                onPressed: onChangeDate,
                child: Text(strings.changeDate),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}';
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.title,
    required this.value,
    this.topSpacing = 0,
  });

  final String title;
  final String value;
  final double topSpacing;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(top: topSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isDark ? const Color(0xFFB8AEA2) : const Color(0xFF8B7E74),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }
}
