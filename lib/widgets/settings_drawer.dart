import 'package:flutter/material.dart';

import '../contollers/quote_contoller.dart';
import '../settings/app_settings.dart';
import '../settings/app_settings_controller.dart';
import '../settings/app_strings.dart';

class SettingsDrawer extends StatelessWidget {
  const SettingsDrawer({
    super.key,
    required this.controller,
    this.embedded = false,
  });

  final AppSettingsController controller;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final settings = controller.settings;
    final strings = AppStrings(settings.language);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sectionTitleColor = isDark
        ? const Color(0xFFB8AEA2)
        : const Color(0xFF8B7E74);

    final content = SafeArea(
      child: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Row(
            children: [
              Text(
                strings.settings,
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
          Text(
            strings.settingsSubtitle,
            style: TextStyle(
              color: sectionTitleColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _SectionTitle(title: strings.languageTitle, color: sectionTitleColor),
          const SizedBox(height: 8),
          _LanguageToggle(
            value: settings.language,
            onChanged: controller.setLanguage,
          ),
          const SizedBox(height: 16),
          _SectionTitle(title: strings.themeTitle, color: sectionTitleColor),
          const SizedBox(height: 8),
          _OptionGrid<AppThemeMode>(
            values: AppThemeMode.values,
            currentValue: settings.themeMode,
            labelBuilder: (value) => value.label(settings.language),
            onSelected: controller.setThemeMode,
          ),
          const SizedBox(height: 16),
          _SectionTitle(
            title: strings.quoteTextTitle,
            color: sectionTitleColor,
          ),
          const SizedBox(height: 8),
          _OptionGrid<QuoteTextSize>(
            values: QuoteTextSize.values,
            currentValue: settings.quoteTextSize,
            labelBuilder: (value) => value.label(settings.language),
            onSelected: controller.setQuoteTextSize,
          ),
          const SizedBox(height: 16),
          _SectionTitle(
            title: strings.lineSpacingTitle,
            color: sectionTitleColor,
          ),
          const SizedBox(height: 8),
          _OptionGrid<QuoteLineSpacing>(
            values: QuoteLineSpacing.values,
            currentValue: settings.quoteLineSpacing,
            labelBuilder: (value) => value.label(settings.language),
            onSelected: controller.setQuoteLineSpacing,
          ),
          const SizedBox(height: 16),
          _SectionTitle(title: strings.uiSizeTitle, color: sectionTitleColor),
          const SizedBox(height: 8),
          _OptionGrid<UiTextSize>(
            values: UiTextSize.values,
            currentValue: settings.uiTextSize,
            labelBuilder: (value) => value.label(settings.language),
            onSelected: controller.setUiTextSize,
          ),
          const SizedBox(height: 16),
          _SectionTitle(title: strings.densityTitle, color: sectionTitleColor),
          const SizedBox(height: 8),
          _OptionGrid<CardDensity>(
            values: CardDensity.values,
            currentValue: settings.cardDensity,
            labelBuilder: (value) => value.label(settings.language),
            onSelected: controller.setCardDensity,
          ),
          const SizedBox(height: 16),
          _SectionTitle(title: strings.tagSizeTitle, color: sectionTitleColor),
          const SizedBox(height: 8),
          _OptionGrid<TagPreviewSize>(
            values: TagPreviewSize.values,
            currentValue: settings.tagPreviewSize,
            labelBuilder: (value) => value.label(settings.language),
            onSelected: controller.setTagPreviewSize,
          ),
          const SizedBox(height: 16),
          _SectionTitle(
            title: strings.collapsedTitle,
            color: sectionTitleColor,
          ),
          const SizedBox(height: 8),
          _OptionGrid<int>(
            values: const [4, 6, 8],
            currentValue: settings.collapsedLines,
            labelBuilder: strings.rows,
            onSelected: controller.setCollapsedLines,
          ),
          const SizedBox(height: 16),
          _SectionTitle(
            title: strings.defaultSortTitle,
            color: sectionTitleColor,
          ),
          const SizedBox(height: 8),
          _OptionGrid<QuoteSortMode>(
            values: QuoteSortMode.values,
            currentValue: settings.defaultSortMode,
            labelBuilder: strings.sortModeLabel,
            columns: 2,
            onSelected: controller.setDefaultSortMode,
          ),
          const SizedBox(height: 16),
          _SectionTitle(
            title: strings.cardPreviewTitle,
            color: sectionTitleColor,
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(strings.showNote),
            value: settings.showNotePreview,
            onChanged: controller.setShowNotePreview,
          ),
          SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(strings.showMeta),
            value: settings.showMetaPreview,
            onChanged: controller.setShowMetaPreview,
          ),
        ],
      ),
    );

    if (embedded) {
      return Material(
        color: isDark ? const Color(0xFF1D2127) : const Color(0xFFF7F1EA),
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: content,
      );
    }

    return Drawer(child: content);
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
        letterSpacing: 0.2,
      ),
    );
  }
}

class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle({required this.value, required this.onChanged});

  final AppLanguage value;
  final Future<void> Function(AppLanguage value) onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = Theme.of(context).colorScheme.primary;
    final inactiveColor = isDark ? const Color(0xFF262B33) : Colors.white;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: inactiveColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: _LanguageToggleItem(
              label: 'RU',
              selected: value == AppLanguage.ru,
              activeColor: activeColor,
              onTap: () => onChanged(AppLanguage.ru),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _LanguageToggleItem(
              label: 'EN',
              selected: value == AppLanguage.en,
              activeColor: activeColor,
              onTap: () => onChanged(AppLanguage.en),
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageToggleItem extends StatelessWidget {
  const _LanguageToggleItem({
    required this.label,
    required this.selected,
    required this.activeColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: selected
                ? Colors.white
                : Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ),
    );
  }
}

class _OptionGrid<T> extends StatelessWidget {
  const _OptionGrid({
    required this.values,
    required this.currentValue,
    required this.labelBuilder,
    required this.onSelected,
    this.columns = 3,
  });

  final List<T> values;
  final T currentValue;
  final String Function(T value) labelBuilder;
  final Future<void> Function(T value) onSelected;
  final int columns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - ((columns - 1) * 8)) / columns;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final value in values)
              SizedBox(
                width: width,
                child: _OptionTile(
                  label: labelBuilder(value),
                  selected: value == currentValue,
                  onTap: () => onSelected(value),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(
                  context,
                ).colorScheme.primary.withAlpha(isDark ? 56 : 34)
              : (isDark ? const Color(0xFF262B33) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).dividerColor,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ),
      ),
    );
  }
}
