import 'package:flutter/material.dart';

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
    final background =
        selected ? const Color(0xFFE8DDD3) : const Color(0xFFF5EEE7);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: background,
          border: Border.all(
            color: selected ? const Color(0xFF4A6FA5) : const Color(0xFFD8CEC5),
            width: 1.2,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: RichText(
          text: TextSpan(
            style: const TextStyle(color: Color(0xFF8B7E74), fontSize: 13),
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
          style: TextStyle(
            backgroundColor: const Color(0xFFD5E2F5),
            color: const Color(0xFF2C2C2C),
            fontWeight: FontWeight.w600,
          ),
        ),
      );

      start = index + lowerNeedle.length;
    }

    return spans;
  }
}
