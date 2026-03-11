import 'package:flutter/material.dart';

import '../contollers/quote_contoller.dart';
import '../settings/app_settings.dart';
import '../settings/app_settings_controller.dart';

class SettingsDrawer extends StatelessWidget {
  const SettingsDrawer({super.key, required this.controller});

  final AppSettingsController controller;

  @override
  Widget build(BuildContext context) {
    final settings = controller.settings;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sectionTitleColor = isDark
        ? const Color(0xFFB8AEA2)
        : const Color(0xFF8B7E74);

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          children: [
            Row(
              children: [
                Text(
                  'Настройки',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Визуал и поведение приложения',
              style: TextStyle(
                color: sectionTitleColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            _SectionTitle(title: 'Тема', color: sectionTitleColor),
            const SizedBox(height: 8),
            _EnumSegment<AppThemeMode>(
              values: AppThemeMode.values,
              currentValue: settings.themeMode,
              labelBuilder: (value) => value.label,
              onSelected: controller.setThemeMode,
            ),
            const SizedBox(height: 18),
            _SectionTitle(title: 'Текст цитаты', color: sectionTitleColor),
            const SizedBox(height: 8),
            _EnumSegment<QuoteTextSize>(
              values: QuoteTextSize.values,
              currentValue: settings.quoteTextSize,
              labelBuilder: (value) => value.label,
              onSelected: controller.setQuoteTextSize,
            ),
            const SizedBox(height: 18),
            _SectionTitle(
              title: 'Межстрочный интервал',
              color: sectionTitleColor,
            ),
            const SizedBox(height: 8),
            _EnumSegment<QuoteLineSpacing>(
              values: QuoteLineSpacing.values,
              currentValue: settings.quoteLineSpacing,
              labelBuilder: (value) => value.label,
              onSelected: controller.setQuoteLineSpacing,
            ),
            const SizedBox(height: 18),
            _SectionTitle(title: 'Размер интерфейса', color: sectionTitleColor),
            const SizedBox(height: 8),
            _EnumSegment<UiTextSize>(
              values: UiTextSize.values,
              currentValue: settings.uiTextSize,
              labelBuilder: (value) => value.label,
              onSelected: controller.setUiTextSize,
            ),
            const SizedBox(height: 18),
            _SectionTitle(
              title: 'Плотность карточек',
              color: sectionTitleColor,
            ),
            const SizedBox(height: 8),
            _EnumSegment<CardDensity>(
              values: CardDensity.values,
              currentValue: settings.cardDensity,
              labelBuilder: (value) => value.label,
              onSelected: controller.setCardDensity,
            ),
            const SizedBox(height: 18),
            _SectionTitle(title: 'Размер тегов', color: sectionTitleColor),
            const SizedBox(height: 8),
            _EnumSegment<TagPreviewSize>(
              values: TagPreviewSize.values,
              currentValue: settings.tagPreviewSize,
              labelBuilder: (value) => value.label,
              onSelected: controller.setTagPreviewSize,
            ),
            const SizedBox(height: 18),
            _SectionTitle(title: 'Свернутая запись', color: sectionTitleColor),
            const SizedBox(height: 8),
            _EnumSegment<int>(
              values: const [4, 6, 8],
              currentValue: settings.collapsedLines,
              labelBuilder: (value) => '$value строк',
              onSelected: controller.setCollapsedLines,
            ),
            const SizedBox(height: 18),
            _SectionTitle(
              title: 'Сортировка по умолчанию',
              color: sectionTitleColor,
            ),
            const SizedBox(height: 8),
            _EnumSegment<QuoteSortMode>(
              values: QuoteSortMode.values,
              currentValue: settings.defaultSortMode,
              labelBuilder: (value) => value.label,
              onSelected: controller.setDefaultSortMode,
            ),
            const SizedBox(height: 18),
            _SectionTitle(
              title: 'Показывать в карточке',
              color: sectionTitleColor,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Заметку'),
              value: settings.showNotePreview,
              onChanged: (value) => controller.setShowNotePreview(value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Автора и источник'),
              value: settings.showMetaPreview,
              onChanged: (value) => controller.setShowMetaPreview(value),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.color});

  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: color,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _EnumSegment<T> extends StatelessWidget {
  const _EnumSegment({
    required this.values,
    required this.currentValue,
    required this.labelBuilder,
    required this.onSelected,
  });

  final List<T> values;
  final T currentValue;
  final String Function(T value) labelBuilder;
  final Future<void> Function(T value) onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final value in values) ...[
            ChoiceChip(
              label: Text(labelBuilder(value)),
              selected: value == currentValue,
              onSelected: (_) {
                onSelected(value);
              },
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}
