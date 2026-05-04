import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../models/saved_filter.dart';
import '../services/pin_lock_service.dart';
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
  String _pinSalt = '';
  String _pinHash = '';

  AppSettings get settings => _settings;

  static Future<AppSettingsController> create() async {
    final box = Hive.box(_boxName);
    final pinSalt = (box.get('appLockPinSalt') as String?) ?? '';
    final pinHash = (box.get('appLockPinHash') as String?) ?? '';
    final appLockConfigured = pinSalt.isNotEmpty && pinHash.isNotEmpty;
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
      appLockEnabled:
          ((box.get('appLockEnabled') as bool?) ?? false) && appLockConfigured,
      appLockConfigured: appLockConfigured,
      biometricUnlockEnabled:
          ((box.get('biometricUnlockEnabled') as bool?) ?? false) &&
          appLockConfigured,
      lastFullExportAt: _readDateTime(box.get('lastFullExportAt')),
      savedFilters: _readSavedFilters(box.get('savedFilters')),
      proUnlocked:
          (box.get('proUnlocked') as bool?) ?? AppSettings.defaults.proUnlocked,
      proUnlockedAt: _readDateTime(box.get('proUnlockedAt')),
    );
    await box.deleteAll(_obsoleteKeys);
    return AppSettingsController._(box, settings)
      .._pinSalt = pinSalt
      .._pinHash = pinHash;
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

  Future<void> setPinLock(String pin) async {
    if (!PinLockService.isValidPin(pin)) {
      throw ArgumentError('PIN must contain 4 to 8 digits.');
    }

    final salt = PinLockService.generateSalt();
    final hash = PinLockService.hashPin(pin, salt);
    _pinSalt = salt;
    _pinHash = hash;
    _settings = _settings.copyWith(
      appLockEnabled: true,
      appLockConfigured: true,
    );
    notifyListeners();
    await _box.putAll({
      'appLockEnabled': true,
      'appLockPinSalt': salt,
      'appLockPinHash': hash,
    });
  }

  Future<void> disablePinLock() async {
    _pinSalt = '';
    _pinHash = '';
    _settings = _settings.copyWith(
      appLockEnabled: false,
      appLockConfigured: false,
      biometricUnlockEnabled: false,
    );
    notifyListeners();
    await _box.putAll({
      'appLockEnabled': false,
      'appLockPinSalt': '',
      'appLockPinHash': '',
      'biometricUnlockEnabled': false,
    });
  }

  Future<void> setBiometricUnlockEnabled(bool value) async {
    final enabled = value && _settings.appLockConfigured;
    await _update(
      _settings.copyWith(biometricUnlockEnabled: enabled),
      'biometricUnlockEnabled',
      enabled,
    );
  }

  Future<void> markFullExported(DateTime exportedAt) async {
    final value = exportedAt.toUtc();
    await _update(
      _settings.copyWith(lastFullExportAt: value),
      'lastFullExportAt',
      value.toIso8601String(),
    );
  }

  Future<void> markProUnlocked(DateTime unlockedAt) async {
    final value = unlockedAt.toUtc();
    _settings = _settings.copyWith(proUnlocked: true, proUnlockedAt: value);
    notifyListeners();
    await _box.putAll({
      'proUnlocked': true,
      'proUnlockedAt': value.toIso8601String(),
    });
  }

  Future<void> saveFilter(SavedFilter filter) async {
    final filters = [
      for (final existing in _settings.savedFilters)
        if (existing.id != filter.id) existing,
      filter,
    ];
    await _updateSavedFilters(filters);
  }

  Future<void> removeSavedFilter(String id) async {
    final filters = [
      for (final filter in _settings.savedFilters)
        if (filter.id != id) filter,
    ];
    await _updateSavedFilters(filters);
  }

  bool verifyPin(String pin) {
    return PinLockService.verifyPin(pin: pin, salt: _pinSalt, hash: _pinHash);
  }

  Future<void> resetSettings() async {
    _settings = AppSettings.defaults.copyWith(
      hasCompletedOnboarding: _settings.hasCompletedOnboarding,
      appLockEnabled: _settings.appLockEnabled,
      appLockConfigured: _settings.appLockConfigured,
      biometricUnlockEnabled: _settings.biometricUnlockEnabled,
      lastFullExportAt: _settings.lastFullExportAt,
      savedFilters: _settings.savedFilters,
      proUnlocked: _settings.proUnlocked,
      proUnlockedAt: _settings.proUnlockedAt,
    );
    notifyListeners();
    final values = <String, Object>{
      'themeMode': _settings.themeMode.key,
      'language': _settings.language.key,
      'quoteTextSize': _settings.quoteTextSize,
      'quoteLineSpacing': _settings.quoteLineSpacing,
      'showNotePreview': _settings.showNotePreview,
      'showMetaPreview': _settings.showMetaPreview,
      'hasCompletedOnboarding': _settings.hasCompletedOnboarding,
      'appLockEnabled': _settings.appLockEnabled,
      'biometricUnlockEnabled': _settings.biometricUnlockEnabled,
      'proUnlocked': _settings.proUnlocked,
    };
    final lastFullExportAt = _settings.lastFullExportAt;
    if (lastFullExportAt != null) {
      values['lastFullExportAt'] = lastFullExportAt.toIso8601String();
    }
    final proUnlockedAt = _settings.proUnlockedAt;
    if (proUnlockedAt != null) {
      values['proUnlockedAt'] = proUnlockedAt.toIso8601String();
    }
    values['savedFilters'] = [
      for (final filter in _settings.savedFilters) filter.toJson(),
    ];
    await _box.putAll(values);
    await _box.deleteAll(_obsoleteKeys);
  }

  Future<void> _updateSavedFilters(List<SavedFilter> filters) async {
    _settings = _settings.copyWith(savedFilters: List.unmodifiable(filters));
    notifyListeners();
    await _box.put('savedFilters', [
      for (final filter in filters) filter.toJson(),
    ]);
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

  static DateTime? _readDateTime(Object? value) {
    if (value is DateTime) {
      return value.toUtc();
    }
    if (value is String) {
      return DateTime.tryParse(value)?.toUtc();
    }
    return null;
  }

  static List<SavedFilter> _readSavedFilters(Object? value) {
    if (value is! List) {
      return const [];
    }
    return [
      for (final item in value)
        if (item is Map)
          SavedFilter.fromJson({
            for (final entry in item.entries)
              if (entry.key is String) entry.key as String: entry.value,
          }),
    ];
  }
}
