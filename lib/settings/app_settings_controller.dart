import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import 'app_settings.dart';

class AppSettingsController extends ChangeNotifier {
  AppSettingsController._(this._box, this._settings);

  static const _boxName = 'settings';
  static const _obsoleteKeys = <String>[
    'uiTextSize',
    'cardDensity',
    'tagPreviewSize',
    'collapsedLines',
    'defaultSortMode',
  ];

  final Box _box;
  AppSettings _settings;

  AppSettings get settings => _settings;

  static Future<AppSettingsController> create() async {
    final box = Hive.box(_boxName);
    final settings = AppSettings(
      themeMode: AppThemeMode.fromKey(box.get('themeMode') as String?),
      language: AppLanguage.fromKey(box.get('language') as String?),
      quoteTextSize: _readQuoteTextSize(box.get('quoteTextSize')),
      quoteLineSpacing: _readQuoteLineSpacing(box.get('quoteLineSpacing')),
      showNotePreview:
          (box.get('showNotePreview') as bool?) ??
          AppSettings.defaults.showNotePreview,
      showMetaPreview:
          (box.get('showMetaPreview') as bool?) ??
          AppSettings.defaults.showMetaPreview,
      hasCompletedOnboarding:
          (box.get('hasCompletedOnboarding') as bool?) ??
          AppSettings.defaults.hasCompletedOnboarding,
    );
    await box.deleteAll(_obsoleteKeys);
    return AppSettingsController._(box, settings);
  }

  Future<void> setThemeMode(AppThemeMode value) =>
      _update(_settings.copyWith(themeMode: value), 'themeMode', value.key);

  Future<void> setLanguage(AppLanguage value) =>
      _update(_settings.copyWith(language: value), 'language', value.key);

  Future<void> toggleTheme() {
    final value = _settings.themeMode == AppThemeMode.light
        ? AppThemeMode.dark
        : AppThemeMode.light;
    return setThemeMode(value);
  }

  Future<void> setQuoteTextSize(double value) =>
      _update(_settings.copyWith(quoteTextSize: value), 'quoteTextSize', value);

  Future<void> setQuoteLineSpacing(double value) => _update(
    _settings.copyWith(quoteLineSpacing: value),
    'quoteLineSpacing',
    value,
  );

  Future<void> setShowNotePreview(bool value) => _update(
    _settings.copyWith(showNotePreview: value),
    'showNotePreview',
    value,
  );

  Future<void> setShowMetaPreview(bool value) => _update(
    _settings.copyWith(showMetaPreview: value),
    'showMetaPreview',
    value,
  );

  Future<void> completeOnboarding() => _update(
    _settings.copyWith(hasCompletedOnboarding: true),
    'hasCompletedOnboarding',
    true,
  );

  Future<void> resetSettings() async {
    _settings = AppSettings.defaults.copyWith(
      hasCompletedOnboarding: _settings.hasCompletedOnboarding,
    );
    notifyListeners();
    await _box.putAll({
      'themeMode': _settings.themeMode.key,
      'language': _settings.language.key,
      'quoteTextSize': _settings.quoteTextSize,
      'quoteLineSpacing': _settings.quoteLineSpacing,
      'showNotePreview': _settings.showNotePreview,
      'showMetaPreview': _settings.showMetaPreview,
      'hasCompletedOnboarding': _settings.hasCompletedOnboarding,
    });
    await _box.deleteAll(_obsoleteKeys);
  }

  Future<void> _update(AppSettings next, String key, Object value) async {
    _settings = next;
    notifyListeners();
    await _box.put(key, value);
  }

  static double _readQuoteTextSize(Object? value) {
    if (value is num) {
      return value.toDouble().clamp(18, 28);
    }

    return switch (value) {
      'extraSmall' => 18,
      'small' => 20,
      'medium' => 22,
      'large' => 24,
      'extraLarge' => 26,
      _ => AppSettings.defaults.quoteTextSize,
    };
  }

  static double _readQuoteLineSpacing(Object? value) {
    if (value is num) {
      return value.toDouble().clamp(1.25, 1.65);
    }

    return switch (value) {
      'tight' => 1.25,
      'compact' => 1.35,
      'normal' => 1.4,
      'relaxed' => 1.5,
      'airy' => 1.58,
      _ => AppSettings.defaults.quoteLineSpacing,
    };
  }
}
