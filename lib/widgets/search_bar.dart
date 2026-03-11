import 'package:flutter/material.dart';

class QuoteSearchBar extends StatelessWidget {
  const QuoteSearchBar({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Theme.of(context).dividerColor, width: 1.5),
    );

    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
      decoration: InputDecoration(
        filled: true,
        fillColor: isDark ? const Color(0xFF262B33) : Colors.white,
        prefixIcon: Icon(
          Icons.search,
          color: isDark ? const Color(0xFFB8AEA2) : const Color(0xFF8B7E74),
        ),
        hintText: hintText,
        hintStyle: TextStyle(
          color: isDark ? const Color(0xFFB8AEA2) : const Color(0xFF8B7E74),
        ),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                onPressed: onClear,
                icon: Icon(
                  Icons.close,
                  color: isDark
                      ? const Color(0xFFB8AEA2)
                      : const Color(0xFF8B7E74),
                ),
              ),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.6,
          ),
        ),
      ),
    );
  }
}
