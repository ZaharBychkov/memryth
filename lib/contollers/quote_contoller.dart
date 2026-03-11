import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/quote.dart';
import '../models/tag.dart';
import '../repositories/quote_repository.dart';
import '../repositories/tag_repository.dart';

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

  String get label => switch (this) {
    QuoteSortMode.newest => 'Сначала новые',
    QuoteSortMode.updated => 'Недавно изменённые',
    QuoteSortMode.oldest => 'Сначала старые',
    QuoteSortMode.random => 'Случайный порядок',
  };

  static QuoteSortMode fromKey(String? value) {
    return QuoteSortMode.values.firstWhere(
      (mode) => mode.key == value,
      orElse: () => QuoteSortMode.newest,
    );
  }
}

class QuoteController extends ChangeNotifier {
  QuoteController({
    required QuoteRepository quoteRepository,
    required TagRepository tagRepository,
    QuoteSortMode initialSortMode = QuoteSortMode.newest,
  }) : _quoteRepository = quoteRepository,
       _tagRepository = tagRepository,
       _sortMode = initialSortMode;

  final QuoteRepository _quoteRepository;
  final TagRepository _tagRepository;
  final Random _random = Random();

  List<Quote> _allQuotes = <Quote>[];
  Map<String, Tag> _tagsById = <String, Tag>{};
  List<String> _randomOrderIds = <String>[];
  List<Quote> _filteredQuotes = <Quote>[];

  int _currentIndex = 0;
  String _searchQuery = '';
  final Set<String> _activeTagFilters = <String>{};
  final Set<QuoteType> _activeTypeFilters = <QuoteType>{};
  bool _favoritesOnly = false;
  QuoteSortMode _sortMode;

  List<Quote> get allQuotes => _allQuotes;
  int get currentIndex => _currentIndex;
  String get searchQuery => _searchQuery;
  int get totalCount => _allQuotes.length;
  Set<String> get activeTagFilters => _activeTagFilters;
  Set<QuoteType> get activeTypeFilters => _activeTypeFilters;
  bool get favoritesOnly => _favoritesOnly;
  QuoteSortMode get sortMode => _sortMode;

  List<Quote> get filteredQuotes => _filteredQuotes;

  Quote? get currentQuote {
    final filtered = filteredQuotes;
    if (filtered.isEmpty) return null;
    _currentIndex = _normalize(_currentIndex, filtered.length);
    return filtered[_currentIndex];
  }

  List<Tag> get allTagsSorted {
    final items = _tagsById.values.toList();
    items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return items;
  }

  List<Tag> tagsForQuote(Quote quote) {
    return quote.tagIds
        .map((id) => _tagsById[id])
        .whereType<Tag>()
        .toList(growable: false);
  }

  void loadInitial() {
    _allQuotes = _quoteRepository.getAll();
    _tagsById = {for (final tag in _tagRepository.getAll()) tag.id: tag};
    _rebuildRandomOrder();
    _recomputeFilteredQuotes();
    _currentIndex = 0;
    notifyListeners();
  }

  void refreshFromStorage() {
    final previousCurrentId = currentQuote?.id;
    _allQuotes = _quoteRepository.getAll();
    _tagsById = {for (final tag in _tagRepository.getAll()) tag.id: tag};
    _rebuildRandomOrder();
    _recomputeFilteredQuotes();

    final filtered = filteredQuotes;
    if (filtered.isEmpty) {
      _currentIndex = 0;
      notifyListeners();
      return;
    }

    final index = filtered.indexWhere((quote) => quote.id == previousCurrentId);
    _currentIndex = index >= 0
        ? index
        : _normalize(_currentIndex, filtered.length);
    notifyListeners();
  }

  void setSearchQuery(String value) {
    _searchQuery = value;
    _recomputeFilteredQuotes();
    _currentIndex = 0;
    notifyListeners();
  }

  void toggleTagFilter(String tagName) {
    if (_activeTagFilters.contains(tagName)) {
      _activeTagFilters.remove(tagName);
    } else {
      _activeTagFilters.add(tagName);
    }
    _recomputeFilteredQuotes();
    _currentIndex = 0;
    notifyListeners();
  }

  void removeTagFilter(String tagName) {
    _activeTagFilters.remove(tagName);
    _recomputeFilteredQuotes();
    _currentIndex = 0;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _activeTagFilters.clear();
    _activeTypeFilters.clear();
    _favoritesOnly = false;
    _recomputeFilteredQuotes();
    _currentIndex = 0;
    notifyListeners();
  }

  void toggleTypeFilter(QuoteType value) {
    if (_activeTypeFilters.contains(value)) {
      _activeTypeFilters.remove(value);
    } else {
      _activeTypeFilters.add(value);
    }
    if (_activeTypeFilters.length == QuoteType.values.length) {
      _activeTypeFilters.clear();
    }
    _recomputeFilteredQuotes();
    _currentIndex = 0;
    notifyListeners();
  }

  void toggleFavoritesOnly() {
    _favoritesOnly = !_favoritesOnly;
    _recomputeFilteredQuotes();
    _currentIndex = 0;
    notifyListeners();
  }

  void setSortMode(QuoteSortMode value) {
    if (_sortMode == value) return;
    _sortMode = value;
    _recomputeFilteredQuotes();
    _currentIndex = 0;
    notifyListeners();
  }

  Future<void> toggleFavorite(Quote quote) async {
    await _quoteRepository.save(
      quote.copyWith(isFavorite: !quote.isFavorite, updatedAt: DateTime.now()),
    );
  }

  bool _matches(Quote quote) {
    if (_favoritesOnly && !quote.isFavorite) {
      return false;
    }

    if (_activeTypeFilters.isNotEmpty &&
        !_activeTypeFilters.contains(quote.type)) {
      return false;
    }

    if (_activeTagFilters.isNotEmpty) {
      final quoteTagNames = tagsForQuote(quote).map((tag) => tag.name).toSet();
      for (final filter in _activeTagFilters) {
        if (!quoteTagNames.contains(filter)) return false;
      }
    }

    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return true;

    final inText = quote.text.toLowerCase().contains(query);
    final inAuthor = quote.author.toLowerCase().contains(query);
    final inSourceTitle = quote.sourceTitle.toLowerCase().contains(query);
    final inSourceDetails = quote.sourceDetails.toLowerCase().contains(query);
    final inNote = quote.note.toLowerCase().contains(query);
    final inTags = tagsForQuote(
      quote,
    ).any((tag) => tag.name.toLowerCase().contains(query));

    return inText ||
        inAuthor ||
        inSourceTitle ||
        inSourceDetails ||
        inNote ||
        inTags;
  }

  List<Quote> _sortQuotes(List<Quote> items) {
    switch (_sortMode) {
      case QuoteSortMode.newest:
        return items.toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case QuoteSortMode.updated:
        return items.toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      case QuoteSortMode.oldest:
        return items.toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case QuoteSortMode.random:
        final byId = <String, Quote>{
          for (final quote in items) quote.id: quote,
        };
        return _randomOrderIds
            .map((id) => byId[id])
            .whereType<Quote>()
            .toList(growable: false);
    }
  }

  void _rebuildRandomOrder() {
    final currentIds = _allQuotes.map((quote) => quote.id).toSet();
    final kept = _randomOrderIds
        .where(currentIds.contains)
        .toList(growable: true);
    final missing =
        currentIds.where((id) => !kept.contains(id)).toList(growable: true)
          ..shuffle(_random);
    kept.addAll(missing);
    _randomOrderIds = kept;
  }

  void _recomputeFilteredQuotes() {
    final filtered = _allQuotes.where(_matches).toList(growable: false);
    _filteredQuotes = _sortQuotes(filtered);
  }

  int _normalize(int value, int length) {
    if (length == 0) return 0;
    final mod = value % length;
    return mod < 0 ? mod + length : mod;
  }
}
