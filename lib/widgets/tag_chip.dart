import 'package:flutter/material.dart';

import '../settings/app_settings.dart';
import '../settings/app_settings_scope.dart';

class TagChip extends StatelessWidget {
  const TagChip({
    super.key,
    required this.tagName,
    required this.query,
    required this.selected,
    required this.onTap,
  });

  final String tagName;
  final String query;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context).settings;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final compact = settings.tagPreviewSize == TagPreviewSize.compact;
    final background = selected
        ? Theme.of(context).colorScheme.primary.withAlpha(isDark ? 60 : 28)
        : (isDark ? const Color(0xFF262B33) : const Color(0xFFF5EEE7));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 5 : 6,
        ),
        decoration: BoxDecoration(
          color: background,
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).dividerColor,
            width: 1.2,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: RichText(
          text: TextSpan(
            style: TextStyle(
              color: isDark ? const Color(0xFFD7CEC3) : const Color(0xFF8B7E74),
              fontSize: compact ? 12 : 13,
            ),
            children: _highlight(tagName, query),
          ),
        ),
      ),
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
