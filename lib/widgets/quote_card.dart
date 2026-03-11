import 'package:flutter/material.dart';

import '../models/quote.dart';
import '../models/tag.dart';
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
  static const int _collapsedMaxLines = 6;
  static const int _expandThresholdLines = 10;
  static const int _notePreviewLines = 3;
  static const TextStyle _quoteTextStyle = TextStyle(
    color: Color(0xFF2C2C2C),
    fontSize: 22,
    height: 1.4,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle _ellipsisStyle = TextStyle(
    color: Color(0xFF8B8B8B),
    fontSize: 25,
    height: 1.35,
    fontWeight: FontWeight.w700,
  );

  bool _expandedTags = false;
  bool _expandedText = false;

  @override
  Widget build(BuildContext context) {
    final tags = widget.tags;
    final showExpandTagsButton = tags.length > _collapsedCount;
    final visibleTags = _expandedTags
        ? tags
        : tags.take(_collapsedCount).toList();
    final quoteSpan = TextSpan(
      style: _quoteTextStyle,
      children: _highlight(widget.quote.text, widget.query),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxTextWidth = constraints.maxWidth - 36;
        final totalTextLines = _measureTextLineCount(
          context: context,
          maxTextWidth: maxTextWidth,
          text: quoteSpan,
        );
        final canExpandText = totalTextLines > _expandThresholdLines;

        return GestureDetector(
          onLongPressStart: widget.onLongPressStart,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(20),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFD8CEC5),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TypeBadge(type: widget.quote.type),
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
                                : const Color(0xFF8B7E74),
                          ),
                        ),
                      ],
                    ),
                    _buildQuoteText(
                      context: context,
                      quoteSpan: quoteSpan,
                      canExpandText: canExpandText,
                      maxTextWidth: maxTextWidth,
                    ),
                    if (canExpandText)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _expandedText = !_expandedText),
                          behavior: HitTestBehavior.opaque,
                          child: Text(
                            _expandedText ? 'Свернуть' : 'Развернуть',
                            style: const TextStyle(
                              color: Color(0xFF4A6FA5),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 14),
                    if (_metaLine.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          _metaLine,
                          style: const TextStyle(
                            color: Color(0xFF8B7E74),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (widget.quote.note.trim().isNotEmpty)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6F4EF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFE2D8CD),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Моя заметка',
                              style: TextStyle(
                                color: Color(0xFF8B7E74),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.quote.note.trim(),
                              maxLines: _notePreviewLines,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF3B342E),
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
                      const Text(
                        'Теги не добавлены',
                        style: TextStyle(
                          color: Color(0xFF8B7E74),
                          fontSize: 13,
                        ),
                      ),
                    if (showExpandTagsButton)
                      TextButton(
                        onPressed: () =>
                            setState(() => _expandedTags = !_expandedTags),
                        child: Text(
                          _expandedTags
                              ? 'Скрыть теги'
                              : 'Показать все теги (${tags.length})',
                          style: const TextStyle(color: Color(0xFF4A6FA5)),
                        ),
                      ),
                  ],
                ),
                ),
              ),
            ),
          ),
        );
      },
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
    return parts.join(' • ');
  }

  Widget _buildQuoteText({
    required BuildContext context,
    required TextSpan quoteSpan,
    required bool canExpandText,
    required double maxTextWidth,
  }) {
    if (!canExpandText || _expandedText) {
      return Text.rich(
        quoteSpan,
        maxLines: null,
        overflow: TextOverflow.visible,
      );
    }

    final collapsedText = _truncateTextForCollapsed(
      context: context,
      source: widget.quote.text,
      maxTextWidth: maxTextWidth,
      suffix: ' ...',
    );

    return Text.rich(
      TextSpan(
        style: _quoteTextStyle,
        children: [
          ..._highlight(collapsedText, widget.query),
          const TextSpan(text: ' ...', style: _ellipsisStyle),
        ],
      ),
      maxLines: _collapsedMaxLines,
      overflow: TextOverflow.clip,
    );
  }

  String _truncateTextForCollapsed({
    required BuildContext context,
    required String source,
    required double maxTextWidth,
    required String suffix,
  }) {
    var low = 0;
    var high = source.length;
    var best = 0;

    while (low <= high) {
      final mid = (low + high) ~/ 2;
      final text = source.substring(0, mid).trimRight();
      final candidate = '$text$suffix';
      final painter = TextPainter(
        text: TextSpan(text: candidate, style: _quoteTextStyle),
        maxLines: _collapsedMaxLines,
        textDirection: Directionality.of(context),
      )..layout(maxWidth: maxTextWidth);

      if (painter.didExceedMaxLines) {
        high = mid - 1;
      } else {
        best = mid;
        low = mid + 1;
      }
    }

    var result = source.substring(0, best).trimRight();
    final lastSpace = result.lastIndexOf(RegExp(r'\s'));
    if (lastSpace > 0) {
      result = result.substring(0, lastSpace).trimRight();
    }

    if (result.isEmpty) {
      return source.substring(0, best.clamp(0, source.length)).trimRight();
    }

    return result;
  }

  int _measureTextLineCount({
    required BuildContext context,
    required double maxTextWidth,
    required TextSpan text,
  }) {
    if (maxTextWidth <= 0 || maxTextWidth == double.infinity) {
      return 0;
    }

    final painter = TextPainter(
      text: text,
      textDirection: Directionality.of(context),
    )..layout(maxWidth: maxTextWidth);

    return painter.computeLineMetrics().length;
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
  const _TypeBadge({required this.type});

  final QuoteType type;

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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 6),
          Text(
            type.label,
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
