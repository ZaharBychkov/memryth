import 'package:flutter/widgets.dart';

import '../contollers/quote_contoller.dart';

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
  });

  final AppThemeMode themeMode;
  final AppLanguage language;
  final double quoteTextSize;
  final double quoteLineSpacing;
  final bool showNotePreview;
  final bool showMetaPreview;
  final bool hasCompletedOnboarding;

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
  );
}
