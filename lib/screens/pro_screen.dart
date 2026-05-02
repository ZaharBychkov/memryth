import 'package:flutter/material.dart';

import '../settings/app_settings.dart';
import '../settings/app_settings_controller.dart';

class ProScreen extends StatelessWidget {
  const ProScreen({super.key, required this.controller});

  final AppSettingsController controller;

  @override
  Widget build(BuildContext context) {
    final text = _ProText(controller.settings.language);

    return Scaffold(
      appBar: AppBar(title: Text(text.title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
          children: [
            _HeroPanel(text: text),
            const SizedBox(height: 18),
            for (final feature in text.features) _FeatureRow(feature: feature),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: null,
              icon: const Icon(Icons.lock_open_rounded),
              label: Text(text.unlockComingSoon),
            ),
            const SizedBox(height: 10),
            Text(
              text.billingNote,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).hintColor,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.text});

  final _ProText text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withAlpha(30),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.workspace_premium_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            text.heroTitle,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(text.heroBody, style: const TextStyle(height: 1.42)),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.feature});

  final _ProFeature feature;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withAlpha(22),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              feature.icon,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  feature.body,
                  style: TextStyle(
                    color: Theme.of(context).hintColor,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProText {
  const _ProText(this.language);

  final AppLanguage language;

  bool get isRu => language == AppLanguage.ru;

  String get title => isRu ? 'MEMRYTH Pro' : 'MEMRYTH Pro';
  String get heroTitle =>
      isRu ? 'Pro без подписки' : 'Pro without subscription';
  String get heroBody => isRu
      ? 'Планируемая модель: бесплатное ядро и разовая покупка Pro для расширенных локальных функций.'
      : 'Planned model: free core features and a one-time Pro unlock for advanced local tools.';
  String get unlockComingSoon =>
      isRu ? 'Покупка через Google Play позже' : 'Google Play unlock later';
  String get billingNote => isRu
      ? 'Платежи не подключены в этой сборке. Экспорт, импорт и базовая защита данных остаются доступными.'
      : 'Payments are not connected in this build. Export, import, and basic data protection remain available.';

  List<_ProFeature> get features {
    if (isRu) {
      return const [
        _ProFeature(
          icon: Icons.backup_rounded,
          title: 'Расширенный backup',
          body: 'Напоминания о backup и более гибкие сценарии экспорта.',
        ),
        _ProFeature(
          icon: Icons.widgets_rounded,
          title: 'Виджеты',
          body: 'Быстрое добавление и возвращение к сохраненным фрагментам.',
        ),
        _ProFeature(
          icon: Icons.checklist_rounded,
          title: 'Batch actions',
          body: 'Массовые действия с записями и темами.',
        ),
        _ProFeature(
          icon: Icons.collections_bookmark_rounded,
          title: 'Коллекции',
          body: 'Сохраненные подборки и расширенная организация библиотеки.',
        ),
      ];
    }

    return const [
      _ProFeature(
        icon: Icons.backup_rounded,
        title: 'Advanced backup',
        body: 'Backup reminders and more flexible export workflows.',
      ),
      _ProFeature(
        icon: Icons.widgets_rounded,
        title: 'Widgets',
        body: 'Quick add and faster return to saved fragments.',
      ),
      _ProFeature(
        icon: Icons.checklist_rounded,
        title: 'Batch actions',
        body: 'Bulk operations for entries and topics.',
      ),
      _ProFeature(
        icon: Icons.collections_bookmark_rounded,
        title: 'Collections',
        body: 'Saved sets and deeper library organization.',
      ),
    ];
  }
}

class _ProFeature {
  const _ProFeature({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}
