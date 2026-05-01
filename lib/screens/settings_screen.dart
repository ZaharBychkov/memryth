import 'package:flutter/material.dart';

import '../contollers/quote_contoller.dart';
import '../settings/app_settings.dart';
import '../settings/app_settings_controller.dart';
import '../settings/app_strings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.controller});

  final AppSettingsController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final text = _SettingsText(controller.settings.language);

        return Scaffold(
          appBar: AppBar(title: Text(text.settings)),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _SettingsTile(
                  icon: Icons.text_fields_rounded,
                  title: text.reading,
                  subtitle: text.readingSubtitle,
                  onTap: () => _push(
                    context,
                    ReadingSettingsScreen(controller: controller),
                  ),
                ),
                _SettingsTile(
                  icon: Icons.archive_rounded,
                  title: text.data,
                  subtitle: text.dataSubtitle,
                  onTap: () => _push(
                    context,
                    DataSettingsScreen(controller: controller),
                  ),
                ),
                _SettingsTile(
                  icon: Icons.privacy_tip_rounded,
                  title: text.privacy,
                  subtitle: text.privacySubtitle,
                  onTap: () => _push(
                    context,
                    PrivacySettingsScreen(controller: controller),
                  ),
                ),
                _SettingsTile(
                  icon: Icons.person_rounded,
                  title: text.account,
                  subtitle: text.accountSubtitle,
                  onTap: () => _push(
                    context,
                    AccountSettingsScreen(controller: controller),
                  ),
                ),
                _SettingsTile(
                  icon: Icons.info_rounded,
                  title: text.about,
                  subtitle: text.aboutSubtitle,
                  onTap: () => _push(
                    context,
                    AboutSettingsScreen(controller: controller),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }
}

class ReadingSettingsScreen extends StatelessWidget {
  const ReadingSettingsScreen({super.key, required this.controller});

  final AppSettingsController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final settings = controller.settings;
        final strings = AppStrings(settings.language);
        final text = _SettingsText(settings.language);

        return Scaffold(
          appBar: AppBar(title: Text(text.reading)),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _PreviewCard(settings: settings),
                const SizedBox(height: 16),
                _SectionTitle(text.appearance),
                _SegmentedOptions<AppThemeMode>(
                  values: AppThemeMode.values,
                  currentValue: settings.themeMode,
                  labelBuilder: (value) => value.label(settings.language),
                  onSelected: controller.setThemeMode,
                ),
                const SizedBox(height: 16),
                _SectionTitle(strings.languageTitle),
                _SegmentedOptions<AppLanguage>(
                  values: AppLanguage.values,
                  currentValue: settings.language,
                  labelBuilder: (value) =>
                      value == AppLanguage.ru ? 'RU' : 'EN',
                  onSelected: controller.setLanguage,
                ),
                const SizedBox(height: 20),
                _SectionTitle(text.readingText),
                _EnumSlider<QuoteTextSize>(
                  values: QuoteTextSize.values,
                  currentValue: settings.quoteTextSize,
                  title: strings.quoteTextTitle,
                  valueLabel: (value) => value.fontSize.toStringAsFixed(0),
                  onChanged: controller.setQuoteTextSize,
                ),
                _EnumSlider<QuoteLineSpacing>(
                  values: QuoteLineSpacing.values,
                  currentValue: settings.quoteLineSpacing,
                  title: strings.lineSpacingTitle,
                  valueLabel: (value) => value.height.toStringAsFixed(2),
                  onChanged: controller.setQuoteLineSpacing,
                ),
                const SizedBox(height: 20),
                _SectionTitle(text.interface),
                _SegmentedOptions<UiTextSize>(
                  values: UiTextSize.values,
                  currentValue: settings.uiTextSize,
                  labelBuilder: (value) => value.label(settings.language),
                  onSelected: controller.setUiTextSize,
                ),
                const SizedBox(height: 12),
                _SegmentedOptions<CardDensity>(
                  values: CardDensity.values,
                  currentValue: settings.cardDensity,
                  labelBuilder: (value) => value.label(settings.language),
                  onSelected: controller.setCardDensity,
                ),
                const SizedBox(height: 12),
                _SegmentedOptions<TagPreviewSize>(
                  values: TagPreviewSize.values,
                  currentValue: settings.tagPreviewSize,
                  labelBuilder: (value) => value.label(settings.language),
                  onSelected: controller.setTagPreviewSize,
                ),
                const SizedBox(height: 20),
                _SectionTitle(text.cards),
                _SegmentedOptions<int>(
                  values: const [4, 6, 8],
                  currentValue: settings.collapsedLines,
                  labelBuilder: strings.rows,
                  onSelected: controller.setCollapsedLines,
                ),
                const SizedBox(height: 12),
                _SegmentedOptions<QuoteSortMode>(
                  values: QuoteSortMode.values,
                  currentValue: settings.defaultSortMode,
                  labelBuilder: strings.sortModeLabel,
                  onSelected: controller.setDefaultSortMode,
                  columns: 2,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(strings.showNote),
                  value: settings.showNotePreview,
                  onChanged: controller.setShowNotePreview,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(strings.showMeta),
                  value: settings.showMetaPreview,
                  onChanged: controller.setShowMetaPreview,
                ),
                const SizedBox(height: 20),
                _SectionTitle(text.reset),
                OutlinedButton.icon(
                  onPressed: () => _confirmReset(context, text),
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: Text(text.resetSettings),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmReset(BuildContext context, _SettingsText text) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(text.resetSettings),
          content: Text(text.resetWarning),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(text.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(text.reset),
            ),
          ],
        );
      },
    );

    if (approved == true) {
      await controller.resetSettings();
    }
  }
}

class DataSettingsScreen extends StatelessWidget {
  const DataSettingsScreen({super.key, required this.controller});

  final AppSettingsController controller;

  @override
  Widget build(BuildContext context) {
    final text = _SettingsText(controller.settings.language);

    return Scaffold(
      appBar: AppBar(title: Text(text.data)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _InfoPanel(
              icon: Icons.storage_rounded,
              title: text.localData,
              body: text.localDataBody,
            ),
            const SizedBox(height: 16),
            _ActionRow(
              icon: Icons.file_upload_rounded,
              title: text.exportLibrary,
              subtitle: text.exportSubtitle,
              onTap: () => _showNextStep(context, text),
            ),
            _ActionRow(
              icon: Icons.file_download_rounded,
              title: text.importLibrary,
              subtitle: text.importSubtitle,
              onTap: () => _showNextStep(context, text),
            ),
          ],
        ),
      ),
    );
  }
}

class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({super.key, required this.controller});

  final AppSettingsController controller;

  @override
  Widget build(BuildContext context) {
    final text = _SettingsText(controller.settings.language);

    return Scaffold(
      appBar: AppBar(title: Text(text.privacy)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _InfoPanel(
              icon: Icons.lock_rounded,
              title: text.offlineFirst,
              body: text.offlineFirstBody,
            ),
            const SizedBox(height: 16),
            _ActionRow(
              icon: Icons.fingerprint_rounded,
              title: text.appLock,
              subtitle: text.appLockSubtitle,
              onTap: () => _showNextStep(context, text),
            ),
          ],
        ),
      ),
    );
  }
}

class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key, required this.controller});

  final AppSettingsController controller;

  @override
  Widget build(BuildContext context) {
    final text = _SettingsText(controller.settings.language);

    return Scaffold(
      appBar: AppBar(title: Text(text.account)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _InfoPanel(
              icon: Icons.person_outline_rounded,
              title: text.noAccountRequired,
              body: text.noAccountRequiredBody,
            ),
            const SizedBox(height: 16),
            _ActionRow(
              icon: Icons.cloud_sync_rounded,
              title: text.syncAccount,
              subtitle: text.syncAccountSubtitle,
              onTap: () => _showNextStep(context, text),
            ),
          ],
        ),
      ),
    );
  }
}

class AboutSettingsScreen extends StatelessWidget {
  const AboutSettingsScreen({super.key, required this.controller});

  final AppSettingsController controller;

  @override
  Widget build(BuildContext context) {
    final text = _SettingsText(controller.settings.language);

    return Scaffold(
      appBar: AppBar(title: Text(text.about)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _InfoPanel(
              icon: Icons.auto_stories_rounded,
              title: 'MEMRYTH',
              body: text.aboutBody,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                _IconShell(icon: icon),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Theme.of(context).hintColor,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = _SettingsText(settings.language);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text.previewTitle,
            style: TextStyle(
              color: isDark ? const Color(0xFFB8AEA2) : const Color(0xFF8B7E74),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            text.previewBody,
            style: TextStyle(
              fontSize: settings.quoteTextSize.fontSize,
              height: settings.quoteLineSpacing.height,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EnumSlider<T> extends StatelessWidget {
  const _EnumSlider({
    required this.values,
    required this.currentValue,
    required this.title,
    required this.valueLabel,
    required this.onChanged,
  });

  final List<T> values;
  final T currentValue;
  final String title;
  final String Function(T value) valueLabel;
  final Future<void> Function(T value) onChanged;

  @override
  Widget build(BuildContext context) {
    final index = values.indexOf(currentValue).clamp(0, values.length - 1);

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                valueLabel(values[index]),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          Slider(
            min: 0,
            max: (values.length - 1).toDouble(),
            divisions: values.length - 1,
            value: index.toDouble(),
            label: valueLabel(values[index]),
            onChanged: (value) => onChanged(values[value.round()]),
          ),
        ],
      ),
    );
  }
}

class _SegmentedOptions<T> extends StatelessWidget {
  const _SegmentedOptions({
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
                child: _OptionButton(
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

class _OptionButton extends StatelessWidget {
  const _OptionButton({
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
      child: Container(
        height: 42,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8),
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

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 6),
      leading: _IconShell(icon: icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconShell(icon: icon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(body, style: const TextStyle(height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IconShell extends StatelessWidget {
  const _IconShell({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262B33) : const Color(0xFFF5EEE7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: Theme.of(context).colorScheme.primary),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).hintColor,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

void _showNextStep(BuildContext context, _SettingsText text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text.nextStep)));
}

class _SettingsText {
  const _SettingsText(this.language);

  final AppLanguage language;

  bool get isRu => language == AppLanguage.ru;

  String get settings => isRu ? 'Настройки' : 'Settings';
  String get reading =>
      isRu ? 'Чтение и внешний вид' : 'Reading and appearance';
  String get readingSubtitle => isRu
      ? 'Тема, язык, размер текста и карточек'
      : 'Theme, language, text size and cards';
  String get data => isRu ? 'Данные и резервная копия' : 'Data and backup';
  String get dataSubtitle => isRu
      ? 'Экспорт, импорт и восстановление библиотеки'
      : 'Export, import and restore your library';
  String get privacy =>
      isRu ? 'Приватность и безопасность' : 'Privacy and security';
  String get privacySubtitle => isRu
      ? 'Локальное хранение, защита и политика'
      : 'Local storage, protection and policy';
  String get account => isRu ? 'Аккаунт' : 'Account';
  String get accountSubtitle => isRu
      ? 'Опциональная синхронизация в будущем'
      : 'Optional sync in the future';
  String get about => isRu ? 'О приложении' : 'About';
  String get aboutSubtitle => isRu
      ? 'Версия, идея продукта и справка'
      : 'Version, product idea and help';
  String get appearance => isRu ? 'Внешний вид' : 'Appearance';
  String get readingText => isRu ? 'Текст записи' : 'Entry text';
  String get interface => isRu ? 'Интерфейс' : 'Interface';
  String get cards => isRu ? 'Карточки' : 'Cards';
  String get reset => isRu ? 'Сброс' : 'Reset';
  String get resetSettings =>
      isRu ? 'Сбросить настройки интерфейса' : 'Reset interface settings';
  String get resetWarning => isRu
      ? 'Записи, теги и заметки не будут удалены. Сбросятся только настройки внешнего вида и чтения.'
      : 'Entries, tags and notes will not be deleted. Only appearance and reading settings will be reset.';
  String get cancel => isRu ? 'Отмена' : 'Cancel';
  String get previewTitle => isRu ? 'Предпросмотр' : 'Preview';
  String get previewBody => isRu
      ? 'Сохраненный фрагмент должен читаться спокойно и без лишнего шума.'
      : 'A saved excerpt should read calmly without visual noise.';
  String get localData => isRu ? 'Локальная библиотека' : 'Local library';
  String get localDataBody => isRu
      ? 'Записи хранятся на устройстве. Экспорт и импорт будут следующим блоком реализации.'
      : 'Entries are stored on this device. Export and import are the next implementation block.';
  String get exportLibrary =>
      isRu ? 'Экспортировать библиотеку' : 'Export library';
  String get exportSubtitle => isRu
      ? 'Сохранить все записи и теги в JSON'
      : 'Save all entries and tags to JSON';
  String get importLibrary =>
      isRu ? 'Импортировать из файла' : 'Import from file';
  String get importSubtitle => isRu
      ? 'Объединить библиотеку с backup-файлом'
      : 'Merge the library with a backup file';
  String get offlineFirst => isRu ? 'Offline-first' : 'Offline-first';
  String get offlineFirstBody => isRu
      ? 'MEMRYTH работает без обязательного аккаунта. Защита приложения и политика конфиденциальности будут вынесены сюда.'
      : 'MEMRYTH works without a required account. App lock and privacy policy will live here.';
  String get appLock => isRu ? 'PIN / биометрия' : 'PIN / biometrics';
  String get appLockSubtitle =>
      isRu ? 'Будущая Pro-функция защиты входа' : 'Future Pro app-lock feature';
  String get noAccountRequired =>
      isRu ? 'Аккаунт не обязателен' : 'No account required';
  String get noAccountRequiredBody => isRu
      ? 'Базовое приложение остается локальным. Аккаунт нужен только для будущей синхронизации и облачного backup.'
      : 'The core app stays local. An account is only for future sync and cloud backup.';
  String get syncAccount => isRu ? 'Синхронизация' : 'Sync';
  String get syncAccountSubtitle => isRu
      ? 'Будущий слой для нескольких устройств'
      : 'Future layer for multiple devices';
  String get aboutBody => isRu
      ? 'Личная офлайн-библиотека мыслей, цитат и фрагментов.'
      : 'A private offline library for thoughts, quotes and excerpts.';
  String get nextStep => isRu
      ? 'Этот раздел будет реализован следующим блоком.'
      : 'This section will be implemented next.';
}
