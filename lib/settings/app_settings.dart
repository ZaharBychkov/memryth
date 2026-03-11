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

enum QuoteTextSize {
  small,
  medium,
  large;

  String get key => switch (this) {
    QuoteTextSize.small => 'small',
    QuoteTextSize.medium => 'medium',
    QuoteTextSize.large => 'large',
  };

  String label(AppLanguage language) => switch ((this, language)) {
    (QuoteTextSize.small, AppLanguage.ru) => 'Маленький',
    (QuoteTextSize.medium, AppLanguage.ru) => 'Обычный',
    (QuoteTextSize.large, AppLanguage.ru) => 'Крупный',
    (QuoteTextSize.small, AppLanguage.en) => 'Small',
    (QuoteTextSize.medium, AppLanguage.en) => 'Medium',
    (QuoteTextSize.large, AppLanguage.en) => 'Large',
  };

  double get fontSize => switch (this) {
    QuoteTextSize.small => 20,
    QuoteTextSize.medium => 22,
    QuoteTextSize.large => 26,
  };

  static QuoteTextSize fromKey(String? value) {
    return QuoteTextSize.values.firstWhere(
      (size) => size.key == value,
      orElse: () => QuoteTextSize.medium,
    );
  }
}

enum QuoteLineSpacing {
  compact,
  normal,
  airy;

  String get key => switch (this) {
    QuoteLineSpacing.compact => 'compact',
    QuoteLineSpacing.normal => 'normal',
    QuoteLineSpacing.airy => 'airy',
  };

  String label(AppLanguage language) => switch ((this, language)) {
    (QuoteLineSpacing.compact, AppLanguage.ru) => 'Компактный',
    (QuoteLineSpacing.normal, AppLanguage.ru) => 'Обычный',
    (QuoteLineSpacing.airy, AppLanguage.ru) => 'Воздушный',
    (QuoteLineSpacing.compact, AppLanguage.en) => 'Compact',
    (QuoteLineSpacing.normal, AppLanguage.en) => 'Normal',
    (QuoteLineSpacing.airy, AppLanguage.en) => 'Airy',
  };

  double get height => switch (this) {
    QuoteLineSpacing.compact => 1.28,
    QuoteLineSpacing.normal => 1.4,
    QuoteLineSpacing.airy => 1.58,
  };

  static QuoteLineSpacing fromKey(String? value) {
    return QuoteLineSpacing.values.firstWhere(
      (spacing) => spacing.key == value,
      orElse: () => QuoteLineSpacing.normal,
    );
  }
}

enum UiTextSize {
  small,
  medium,
  large;

  String get key => switch (this) {
    UiTextSize.small => 'small',
    UiTextSize.medium => 'medium',
    UiTextSize.large => 'large',
  };

  String label(AppLanguage language) => switch ((this, language)) {
    (UiTextSize.small, AppLanguage.ru) => 'Маленький',
    (UiTextSize.medium, AppLanguage.ru) => 'Обычный',
    (UiTextSize.large, AppLanguage.ru) => 'Крупный',
    (UiTextSize.small, AppLanguage.en) => 'Small',
    (UiTextSize.medium, AppLanguage.en) => 'Medium',
    (UiTextSize.large, AppLanguage.en) => 'Large',
  };

  double get scale => switch (this) {
    UiTextSize.small => 0.92,
    UiTextSize.medium => 1.0,
    UiTextSize.large => 1.08,
  };

  static UiTextSize fromKey(String? value) {
    return UiTextSize.values.firstWhere(
      (size) => size.key == value,
      orElse: () => UiTextSize.medium,
    );
  }
}

enum CardDensity {
  compact,
  comfortable;

  String get key => switch (this) {
    CardDensity.compact => 'compact',
    CardDensity.comfortable => 'comfortable',
  };

  String label(AppLanguage language) => switch ((this, language)) {
    (CardDensity.compact, AppLanguage.ru) => 'Компактно',
    (CardDensity.comfortable, AppLanguage.ru) => 'Свободно',
    (CardDensity.compact, AppLanguage.en) => 'Compact',
    (CardDensity.comfortable, AppLanguage.en) => 'Comfortable',
  };

  double get cardPadding => switch (this) {
    CardDensity.compact => 14,
    CardDensity.comfortable => 18,
  };

  double get cardSpacing => switch (this) {
    CardDensity.compact => 8,
    CardDensity.comfortable => 10,
  };

  static CardDensity fromKey(String? value) {
    return CardDensity.values.firstWhere(
      (density) => density.key == value,
      orElse: () => CardDensity.comfortable,
    );
  }
}

enum TagPreviewSize {
  compact,
  regular;

  String get key => switch (this) {
    TagPreviewSize.compact => 'compact',
    TagPreviewSize.regular => 'regular',
  };

  String label(AppLanguage language) => switch ((this, language)) {
    (TagPreviewSize.compact, AppLanguage.ru) => 'Мелкие',
    (TagPreviewSize.regular, AppLanguage.ru) => 'Обычные',
    (TagPreviewSize.compact, AppLanguage.en) => 'Small',
    (TagPreviewSize.regular, AppLanguage.en) => 'Regular',
  };

  static TagPreviewSize fromKey(String? value) {
    return TagPreviewSize.values.firstWhere(
      (size) => size.key == value,
      orElse: () => TagPreviewSize.regular,
    );
  }
}

class AppSettings {
  const AppSettings({
    required this.themeMode,
    required this.language,
    required this.quoteTextSize,
    required this.quoteLineSpacing,
    required this.uiTextSize,
    required this.cardDensity,
    required this.showNotePreview,
    required this.showMetaPreview,
    required this.collapsedLines,
    required this.defaultSortMode,
    required this.tagPreviewSize,
  });

  final AppThemeMode themeMode;
  final AppLanguage language;
  final QuoteTextSize quoteTextSize;
  final QuoteLineSpacing quoteLineSpacing;
  final UiTextSize uiTextSize;
  final CardDensity cardDensity;
  final bool showNotePreview;
  final bool showMetaPreview;
  final int collapsedLines;
  final QuoteSortMode defaultSortMode;
  final TagPreviewSize tagPreviewSize;

  bool get isDarkMode => themeMode == AppThemeMode.dark;

  AppSettings copyWith({
    AppThemeMode? themeMode,
    AppLanguage? language,
    QuoteTextSize? quoteTextSize,
    QuoteLineSpacing? quoteLineSpacing,
    UiTextSize? uiTextSize,
    CardDensity? cardDensity,
    bool? showNotePreview,
    bool? showMetaPreview,
    int? collapsedLines,
    QuoteSortMode? defaultSortMode,
    TagPreviewSize? tagPreviewSize,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      quoteTextSize: quoteTextSize ?? this.quoteTextSize,
      quoteLineSpacing: quoteLineSpacing ?? this.quoteLineSpacing,
      uiTextSize: uiTextSize ?? this.uiTextSize,
      cardDensity: cardDensity ?? this.cardDensity,
      showNotePreview: showNotePreview ?? this.showNotePreview,
      showMetaPreview: showMetaPreview ?? this.showMetaPreview,
      collapsedLines: collapsedLines ?? this.collapsedLines,
      defaultSortMode: defaultSortMode ?? this.defaultSortMode,
      tagPreviewSize: tagPreviewSize ?? this.tagPreviewSize,
    );
  }

  static const defaults = AppSettings(
    themeMode: AppThemeMode.light,
    language: AppLanguage.ru,
    quoteTextSize: QuoteTextSize.medium,
    quoteLineSpacing: QuoteLineSpacing.normal,
    uiTextSize: UiTextSize.medium,
    cardDensity: CardDensity.comfortable,
    showNotePreview: true,
    showMetaPreview: true,
    collapsedLines: 6,
    defaultSortMode: QuoteSortMode.newest,
    tagPreviewSize: TagPreviewSize.regular,
  );
}
