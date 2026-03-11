import 'package:flutter/material.dart';

import '../models/quote.dart';
import '../models/tag.dart';
import '../settings/app_settings.dart';
import '../settings/app_settings_scope.dart';
import '../settings/app_strings.dart';
import 'tag_chip.dart';

class QuoteCard extends StatefulWidget {
  const QuoteCard({
    super.key,
    required this.quote,
    required this.tags,
    required this.query,
    required this.activeTagFilters,
    required this.onTagTap,
    required this.onTap,
    required this.onFavoriteToggle,
    this.onLongPressStart,
  });

  final Quote quote;
  final List<Tag> tags;
  final String query;
  final Set<String> activeTagFilters;
  final ValueChanged<String> onTagTap;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final GestureLongPressStartCallback? onLongPressStart;

  @override
  State<QuoteCard> createState() => _QuoteCardState();
}

class _QuoteCardState extends State<QuoteCard> {
  static const int _collapsedCount = 6;
  static const int _expandThresholdChars = 280;

  bool _expandedTags = false;
  bool _expandedText = false;

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context).settings;
    final strings = AppStrings(settings.language);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final padding = settings.cardDensity.cardPadding;
    final quoteTextStyle = TextStyle(
      color: Theme.of(context).textTheme.bodyLarge?.color,
      fontSize: settings.quoteTextSize.fontSize,
      height: settings.quoteLineSpacing.height,
      fontWeight: FontWeight.w600,
    );

    final tags = widget.tags;
    final showExpandTagsButton = tags.length > _collapsedCount;
    final visibleTags = _expandedTags
        ? tags
        : tags.take(_collapsedCount).toList();
    final canExpandText = widget.quote.text.trim().length > _expandThresholdChars;
    final quoteSpan = TextSpan(
      style: quoteTextStyle,
      children: _highlight(widget.quote.text, widget.query),
    );

    return GestureDetector(
      onLongPressStart: widget.onLongPressStart,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(padding),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TypeBadge(
                        type: widget.quote.type,
                        label: strings.quoteTypeLabel(widget.quote.type),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: widget.onFavoriteToggle,
                        visualDensity: VisualDensity.compact,
                        splashRadius: 20,
                        icon: Icon(
                          widget.quote.isFavorite
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: widget.quote.isFavorite
                              ? const Color(0xFFE4A11B)
                              : (isDark
                                    ? const Color(0xFFB8AEA2)
                                    : const Color(0xFF8B7E74)),
                        ),
                      ),
                    ],
                  ),
                  _buildQuoteText(
                    quoteSpan: quoteSpan,
                    canExpandText: canExpandText,
                    collapsedLines: settings.collapsedLines,
                  ),
                  if (canExpandText)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _expandedText = !_expandedText),
                        behavior: HitTestBehavior.opaque,
                        child: Text(
                          _expandedText ? strings.collapse : strings.expand,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  SizedBox(
                    height: settings.cardDensity == CardDensity.compact
                        ? 10
                        : 14,
                  ),
                  if (settings.showMetaPreview && _metaLine.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        _metaLine,
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFFB8AEA2)
                              : const Color(0xFF8B7E74),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (settings.showNotePreview &&
                      widget.quote.note.trim().isNotEmpty)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF262B33)
                            : const Color(0xFFF6F4EF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.myNote,
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xFFB8AEA2)
                                  : const Color(0xFF8B7E74),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.quote.note.trim(),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodyMedium?.color,
                              fontSize: 14,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (visibleTags.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final tag in visibleTags)
                          TagChip(
                            tagName: tag.name,
                            query: widget.query,
                            selected: widget.activeTagFilters.contains(
                              tag.name,
                            ),
                            onTap: () => widget.onTagTap(tag.name),
                          ),
                      ],
                    )
                  else
                    Text(
                      strings.tagNone,
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFFB8AEA2)
                            : const Color(0xFF8B7E74),
                        fontSize: 13,
                      ),
                    ),
                  if (showExpandTagsButton)
                    TextButton(
                      onPressed: () =>
                          setState(() => _expandedTags = !_expandedTags),
                      child: Text(
                        _expandedTags
                            ? strings.hideTags
                            : strings.showAllTags(tags.length),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get _metaLine {
    final parts = <String>[];
    if (widget.quote.author.trim().isNotEmpty) {
      parts.add(widget.quote.author.trim());
    }
    if (widget.quote.sourceTitle.trim().isNotEmpty) {
      parts.add(widget.quote.sourceTitle.trim());
    }
    if (widget.quote.sourceDetails.trim().isNotEmpty) {
      parts.add(widget.quote.sourceDetails.trim());
    }
    return parts.join(' вЂў ');
  }

  Widget _buildQuoteText({
    required TextSpan quoteSpan,
    required bool canExpandText,
    required int collapsedLines,
  }) {
    if (!canExpandText || _expandedText) {
      return Text.rich(
        quoteSpan,
        maxLines: null,
        overflow: TextOverflow.visible,
      );
    }

    return Text.rich(
      quoteSpan,
      maxLines: collapsedLines,
      overflow: TextOverflow.ellipsis,
    );
  }

  List<TextSpan> _highlight(String source, String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return <TextSpan>[TextSpan(text: source)];

    final lowerSource = source.toLowerCase();
    final lowerNeedle = trimmed.toLowerCase();
    final spans = <TextSpan>[];
    var start = 0;

    while (true) {
      final index = lowerSource.indexOf(lowerNeedle, start);
      if (index < 0) {
        if (start < source.length) {
          spans.add(TextSpan(text: source.substring(start)));
        }
        break;
      }

      if (index > start) {
        spans.add(TextSpan(text: source.substring(start, index)));
      }

      spans.add(
        TextSpan(
          text: source.substring(index, index + lowerNeedle.length),
          style: const TextStyle(
            backgroundColor: Color(0xFFD5E2F5),
            color: Color(0xFF2C2C2C),
            fontWeight: FontWeight.w600,
          ),
        ),
      );

      start = index + lowerNeedle.length;
    }

    return spans;
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type, required this.label});

  final QuoteType type;
  final String label;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, icon) = switch (type) {
      QuoteType.quote => (
        const Color(0xFFE8EEF8),
        const Color(0xFF395A8A),
        Icons.format_quote_rounded,
      ),
      QuoteType.thought => (
        const Color(0xFFECE6FA),
        const Color(0xFF6A4FA3),
        Icons.psychology_rounded,
      ),
      QuoteType.excerpt => (
        const Color(0xFFE7F4EE),
        const Color(0xFF3C7B5A),
        Icons.menu_book_rounded,
      ),
    };
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? foreground.withAlpha(32) : background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
