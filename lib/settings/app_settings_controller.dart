import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../contollers/quote_contoller.dart';
import 'app_settings.dart';

class AppSettingsController extends ChangeNotifier {
  AppSettingsController._(this._box, this._settings);

  static const _boxName = 'settings';

  final Box _box;
  AppSettings _settings;

  AppSettings get settings => _settings;

  static Future<AppSettingsController> create() async {
    final box = Hive.box(_boxName);
    final settings = AppSettings(
      themeMode: AppThemeMode.fromKey(box.get('themeMode') as String?),
      language: AppLanguage.fromKey(box.get('language') as String?),
      quoteTextSize: QuoteTextSize.fromKey(box.get('quoteTextSize') as String?),
      quoteLineSpacing: QuoteLineSpacing.fromKey(
        box.get('quoteLineSpacing') as String?,
      ),
      uiTextSize: UiTextSize.fromKey(box.get('uiTextSize') as String?),
      cardDensity: CardDensity.fromKey(box.get('cardDensity') as String?),
      showNotePreview:
          (box.get('showNotePreview') as bool?) ??
          AppSettings.defaults.showNotePreview,
      showMetaPreview:
          (box.get('showMetaPreview') as bool?) ??
          AppSettings.defaults.showMetaPreview,
      collapsedLines:
          (box.get('collapsedLines') as int?) ??
          AppSettings.defaults.collapsedLines,
      defaultSortMode: QuoteSortMode.fromKey(
        box.get('defaultSortMode') as String?,
      ),
      tagPreviewSize: TagPreviewSize.fromKey(
        box.get('tagPreviewSize') as String?,
      ),
    );
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

  Future<void> setQuoteTextSize(QuoteTextSize value) => _update(
    _settings.copyWith(quoteTextSize: value),
    'quoteTextSize',
    value.key,
  );

  Future<void> setQuoteLineSpacing(QuoteLineSpacing value) => _update(
    _settings.copyWith(quoteLineSpacing: value),
    'quoteLineSpacing',
    value.key,
  );

  Future<void> setUiTextSize(UiTextSize value) =>
      _update(_settings.copyWith(uiTextSize: value), 'uiTextSize', value.key);

  Future<void> setCardDensity(CardDensity value) =>
      _update(_settings.copyWith(cardDensity: value), 'cardDensity', value.key);

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

  Future<void> setCollapsedLines(int value) => _update(
    _settings.copyWith(collapsedLines: value),
    'collapsedLines',
    value,
  );

  Future<void> setDefaultSortMode(QuoteSortMode value) => _update(
    _settings.copyWith(defaultSortMode: value),
    'defaultSortMode',
    value.key,
  );

  Future<void> setTagPreviewSize(TagPreviewSize value) => _update(
    _settings.copyWith(tagPreviewSize: value),
    'tagPreviewSize',
    value.key,
  );

  Future<void> _update(AppSettings next, String key, Object value) async {
    _settings = next;
    notifyListeners();
    await _box.put(key, value);
  }
}
