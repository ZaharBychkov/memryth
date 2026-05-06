import 'package:flutter/widgets.dart';

import '../models/quote_sort_mode.dart';

enum AppThemeMode {
  light,
  dark;

  String get key => switch (this) {
    AppThemeMode.light => 'light',
    AppThemeMode.dark => 'dark',
  };

  String label(AppLanguage language) => switch ((this, language)) {
    (AppThemeMode.light, AppLanguage.ru) => 'Светлая',
    (AppThemeMode.dark, AppLanguage.ru) => 'Тёмная',
    (AppThemeMode.light, AppLanguage.en) => 'Light',
    (AppThemeMode.dark, AppLanguage.en) => 'Dark',
  };

  static AppThemeMode fromKey(String? value) {
    return AppThemeMode.values.firstWhere(
      (mode) => mode.key == value,
      orElse: () => AppThemeMode.light,
    );
  }
}

enum AppLanguage {
  ru,
  en;

  String get key => switch (this) {
    AppLanguage.ru => 'ru',
    AppLanguage.en => 'en',
  };

  static AppLanguage fromKey(String? value) {
    return AppLanguage.values.firstWhere(
      (language) => language.key == value,
      orElse: () => AppLanguage.ru,
    );
  }
}

class AppSettings {
  const AppSettings({
    required this.themeMode,
    required this.language,
    required this.quoteTextSize,
    required this.quoteLineSpacing,
    required this.showNotePreview,
    required this.showMetaPreview,
    required this.hasCompletedOnboarding,
    required this.appLockEnabled,
    required this.appLockConfigured,
    required this.biometricUnlockEnabled,
    required this.lastFullExportAt,
    required this.proUnlocked,
    required this.proUnlockedAt,
  });

  final AppThemeMode themeMode;
  final AppLanguage language;
  final double quoteTextSize;
  final double quoteLineSpacing;
  final bool showNotePreview;
  final bool showMetaPreview;
  final bool hasCompletedOnboarding;
  final bool appLockEnabled;
  final bool appLockConfigured;
  final bool biometricUnlockEnabled;
  final DateTime? lastFullExportAt;
  final bool proUnlocked;
  final DateTime? proUnlockedAt;

  bool get isDarkMode => themeMode == AppThemeMode.dark;
  double get uiTextScale => 1;
  double get cardPadding => 18;
  double get cardSpacing => 10;
  double get tagFontSize => 13;
  EdgeInsets get tagPadding =>
      const EdgeInsets.symmetric(horizontal: 10, vertical: 6);
  int get collapsedLines => 6;
  QuoteSortMode get defaultSortMode => QuoteSortMode.newest;

  AppSettings copyWith({
    AppThemeMode? themeMode,
    AppLanguage? language,
    double? quoteTextSize,
    double? quoteLineSpacing,
    bool? showNotePreview,
    bool? showMetaPreview,
    bool? hasCompletedOnboarding,
    bool? appLockEnabled,
    bool? appLockConfigured,
    bool? biometricUnlockEnabled,
    DateTime? lastFullExportAt,
    bool? proUnlocked,
    DateTime? proUnlockedAt,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      quoteTextSize: quoteTextSize ?? this.quoteTextSize,
      quoteLineSpacing: quoteLineSpacing ?? this.quoteLineSpacing,
      showNotePreview: showNotePreview ?? this.showNotePreview,
      showMetaPreview: showMetaPreview ?? this.showMetaPreview,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      appLockConfigured: appLockConfigured ?? this.appLockConfigured,
      biometricUnlockEnabled:
          biometricUnlockEnabled ?? this.biometricUnlockEnabled,
      lastFullExportAt: lastFullExportAt ?? this.lastFullExportAt,
      proUnlocked: proUnlocked ?? this.proUnlocked,
      proUnlockedAt: proUnlockedAt ?? this.proUnlockedAt,
    );
  }

  static const defaults = AppSettings(
    themeMode: AppThemeMode.light,
    language: AppLanguage.ru,
    quoteTextSize: 22,
    quoteLineSpacing: 1.4,
    showNotePreview: true,
    showMetaPreview: true,
    hasCompletedOnboarding: false,
    appLockEnabled: false,
    appLockConfigured: false,
    biometricUnlockEnabled: false,
    lastFullExportAt: null,
    proUnlocked: false,
    proUnlockedAt: null,
  );
}
