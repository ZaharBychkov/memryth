import 'package:flutter/material.dart';

class QuoteSearchBar extends StatelessWidget {
  const QuoteSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFD8CEC5), width: 1.5),
    );

    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        prefixIcon: const Icon(Icons.search, color: Color(0xFF8B7E74)),
        hintText: 'Поиск по тексту, автору, тегам',
        hintStyle: const TextStyle(color: Color(0xFF8B7E74)),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close, color: Color(0xFF8B7E74)),
              ),
        border: border,
        enabledBorder: border,
        focusedBorder: border,
      ),
    );
  }
}
