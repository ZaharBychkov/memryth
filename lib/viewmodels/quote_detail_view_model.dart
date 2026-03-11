import 'package:flutter/foundation.dart';

import '../models/quote.dart';
import '../models/tag.dart';
import '../repositories/quote_repository.dart';
import '../repositories/tag_repository.dart';

class QuoteDetailViewModel extends ChangeNotifier {
  QuoteDetailViewModel({
    required Quote quote,
    required List<Tag> tags,
    required QuoteRepository quoteRepository,
    required TagRepository tagRepository,
  }) : _quote = quote,
       _tags = tags,
       _quoteRepository = quoteRepository,
       _tagRepository = tagRepository;

  final QuoteRepository _quoteRepository;
  final TagRepository _tagRepository;

  Quote _quote;
  List<Tag> _tags;
  bool _detailsExpanded = false;

  Quote get quote => _quote;
  List<Tag> get tags => _tags;
  bool get detailsExpanded => _detailsExpanded;
  QuoteRepository get quoteRepository => _quoteRepository;
  TagRepository get tagRepository => _tagRepository;

  void toggleDetailsExpanded() {
    _detailsExpanded = !_detailsExpanded;
    notifyListeners();
  }

  Future<void> toggleFavorite() async {
    final updated = _quote.copyWith(
      isFavorite: !_quote.isFavorite,
      updatedAt: DateTime.now(),
    );
    await _quoteRepository.save(updated);
    _quote = updated;
    notifyListeners();
  }

  Future<void> updateCreatedAt(DateTime picked) async {
    final updated = _quote.copyWith(
      createdAt: DateTime(
        picked.year,
        picked.month,
        picked.day,
        _quote.createdAt.hour,
        _quote.createdAt.minute,
      ),
      updatedAt: DateTime.now(),
    );
    await _quoteRepository.save(updated);
    _quote = updated;
    notifyListeners();
  }

  void refreshFromStorage() {
    final quotes = _quoteRepository.getAll();
    Quote? refreshed;
    for (final quote in quotes) {
      if (quote.id == _quote.id) {
        refreshed = quote;
        break;
      }
    }
    if (refreshed == null) {
      return;
    }

    final tagsById = {for (final tag in _tagRepository.getAll()) tag.id: tag};
    _quote = refreshed;
    _tags = _quote.tagIds.map((id) => tagsById[id]).whereType<Tag>().toList();
    notifyListeners();
  }
}
