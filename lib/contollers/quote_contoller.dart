import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/quote.dart';
import '../models/tag.dart';
import '../repositories/quote_repository.dart';
import '../repositories/tag_repository.dart';

class QuoteController extends ChangeNotifier {
  QuoteController({
    required QuoteRepository quoteRepository,
    required TagRepository tagRepository,
  })  : _quoteRepository = quoteRepository,
        _tagRepository = tagRepository;

  final QuoteRepository _quoteRepository;
  final TagRepository _tagRepository;
  final Random _random = Random();

  List<Quote> _allQuotes = <Quote>[];
  Map<String, Tag> _tagsById = <String, Tag>{};
  List<String> _orderIds = <String>[];

  int _currentIndex = 0;
  String _searchQuery = '';
  final Set<String> _activeTagFilters = <String>{};

  List<Quote> get allQuotes => _allQuotes;
  int get currentIndex => _currentIndex;
  String get searchQuery => _searchQuery;
  int get totalCount => _allQuotes.length;
  Set<String> get activeTagFilters => _activeTagFilters;

  List<Quote> get filteredQuotes {
    final map = <String, Quote>{for (final q in _allQuotes) q.id: q};
    final ordered = _orderIds.map((id) => map[id]).whereType<Quote>();
    return ordered.where(_matches).toList(growable: false);
  }

  Quote? get currentQuote {
    final filtered = filteredQuotes;
    if (filtered.isEmpty) return null;
    _currentIndex = _normalize(_currentIndex, filtered.length);
    return filtered[_currentIndex];
  }

  List<Tag> tagsForQuote(Quote quote) {
    return quote.tagIds
        .map((id) => _tagsById[id])
        .whereType<Tag>()
        .toList(growable: false);
  }

  String tagNameById(String id) => _tagsById[id]?.name ?? '';

  void loadInitial() {
    _allQuotes = _quoteRepository.getAll();
    _tagsById = {for (final tag in _tagRepository.getAll()) tag.id: tag};
    _shuffleOrder();
    _currentIndex = 0;
    notifyListeners();
  }

  void refreshFromStorage() {
    final previousCurrentId = currentQuote?.id;
    _allQuotes = _quoteRepository.getAll();
    _tagsById = {for (final tag in _tagRepository.getAll()) tag.id: tag};
    _rebuildOrderKeepingRelativeOrder();

    final filtered = filteredQuotes;
    if (filtered.isEmpty) {
      _currentIndex = 0;
      notifyListeners();
      return;
    }

    final idx = filtered.indexWhere((q) => q.id == previousCurrentId);
    _currentIndex = idx >= 0 ? idx : _normalize(_currentIndex, filtered.length);
    notifyListeners();
  }

  void setSearchQuery(String value) {
    _searchQuery = value;
    _currentIndex = 0;
    notifyListeners();
  }

  void toggleTagFilter(String tagName) {
    if (_activeTagFilters.contains(tagName)) {
      _activeTagFilters.remove(tagName);
    } else {
      _activeTagFilters.add(tagName);
    }
    _currentIndex = 0;
    notifyListeners();
  }

  void removeTagFilter(String tagName) {
    _activeTagFilters.remove(tagName);
    _currentIndex = 0;
    notifyListeners();
  }

  void next() {
    final filtered = filteredQuotes;
    if (filtered.isEmpty) return;
    _currentIndex = (_currentIndex + 1) % filtered.length;
    notifyListeners();
  }

  void previous() {
    final filtered = filteredQuotes;
    if (filtered.isEmpty) return;
    _currentIndex = (_currentIndex - 1) % filtered.length;
    if (_currentIndex < 0) _currentIndex = filtered.length - 1;
    notifyListeners();
  }

  bool _matches(Quote quote) {
    if (_activeTagFilters.isNotEmpty) {
      final quoteTagNames = tagsForQuote(quote).map((e) => e.name).toSet();
      for (final filter in _activeTagFilters) {
        if (!quoteTagNames.contains(filter)) return false;
      }
    }

    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return true;

    final inText = quote.text.toLowerCase().contains(query);
    final inAuthor = quote.author.toLowerCase().contains(query);
    final inTags =
        tagsForQuote(quote).any((tag) => tag.name.toLowerCase().contains(query));

    return inText || inAuthor || inTags;
  }

  void _shuffleOrder() {
    _orderIds = _allQuotes.map((q) => q.id).toList(growable: false)..shuffle(_random);
  }

  void _rebuildOrderKeepingRelativeOrder() {
    final idsNow = _allQuotes.map((q) => q.id).toSet();
    final kept = _orderIds.where(idsNow.contains).toList(growable: true);
    final missing = idsNow.where((id) => !kept.contains(id)).toList(growable: true)
      ..shuffle(_random);
    kept.addAll(missing);
    _orderIds = kept;
  }

  int _normalize(int value, int length) {
    if (length == 0) return 0;
    final mod = value % length;
    return mod < 0 ? mod + length : mod;
  }
}
