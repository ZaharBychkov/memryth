enum QuoteSortMode {
  newest,
  updated,
  oldest,
  random;

  String get key => switch (this) {
    QuoteSortMode.newest => 'newest',
    QuoteSortMode.updated => 'updated',
    QuoteSortMode.oldest => 'oldest',
    QuoteSortMode.random => 'random',
  };

  static QuoteSortMode fromKey(String? value) {
    return QuoteSortMode.values.firstWhere(
      (mode) => mode.key == value,
      orElse: () => QuoteSortMode.newest,
    );
  }
}
