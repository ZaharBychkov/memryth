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
    this.onLongPressStart,
  });

  final Quote quote;
  final List<Tag> tags;
  final String query;
  final Set<String> activeTagFilters;
  final ValueChanged<String> onTagTap;
  final GestureLongPressStartCallback? onLongPressStart;

  @override
  State<QuoteCard> createState() => _QuoteCardState();
}

class _QuoteCardState extends State<QuoteCard> {
  static const int _collapsedCount = 6;
  static const int _collapsedMaxLines = 6;
  static const int _expandThresholdLines = 10;
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
          onTap: canExpandText
              ? () => setState(() => _expandedText = !_expandedText)
              : null,
          onLongPressStart: widget.onLongPressStart,
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
                border: Border.all(color: const Color(0xFFD8CEC5), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuoteText(
                    context: context,
                    quoteSpan: quoteSpan,
                    canExpandText: canExpandText,
                    maxTextWidth: maxTextWidth,
                  ),
                  if (canExpandText)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _expandedText ? 'Свернуть' : 'Развернуть',
                        style: const TextStyle(
                          color: Color(0xFF4A6FA5),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 14),
                  if (widget.quote.author.trim().isNotEmpty)
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          color: Color(0xFF8B7E74),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        children: _highlight(widget.quote.author, widget.query),
                      ),
                    ),
                  const SizedBox(height: 14),
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
                      style: TextStyle(color: Color(0xFF8B7E74), fontSize: 13),
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
        );
      },
    );
  }

  Widget _buildQuoteText({
    required BuildContext context,
    required TextSpan quoteSpan,
    required bool canExpandText,
    required double maxTextWidth,
  }) {
    if (_expandedText || !canExpandText) {
      return Text.rich(
        quoteSpan,
        maxLines: _expandedText ? null : _collapsedMaxLines,
        overflow: _expandedText ? TextOverflow.visible : TextOverflow.clip,
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
