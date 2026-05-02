import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:memryth_dart_project/contollers/quote_contoller.dart';
import 'package:memryth_dart_project/models/quote.dart';
import 'package:memryth_dart_project/models/tag.dart';
import 'package:memryth_dart_project/repositories/quote_repository.dart';
import 'package:memryth_dart_project/repositories/tag_repository.dart';
import 'package:memryth_dart_project/viewmodels/topic_index.dart';

void main() {
  group('QuoteController search', () {
    test('finds entries by topic when the text does not contain the query', () {
      final controller = _controller(
        quotes: [
          _quote(id: 'q1', text: 'Важный разговор', tagIds: ['family']),
          _quote(id: 'q2', text: 'Рабочая идея', tagIds: ['work']),
        ],
        tags: [
          Tag(id: 'family', name: 'семья'),
          Tag(id: 'work', name: 'работа'),
        ],
      );

      controller.setSearchQuery('семья');

      expect(controller.filteredQuotes.map((quote) => quote.id), ['q1']);
    });

    test('hash query searches topics only', () {
      final controller = _controller(
        quotes: [
          _quote(id: 'q1', text: 'Важный разговор', tagIds: ['family']),
          _quote(id: 'q2', text: 'семья в тексте', tagIds: ['work']),
        ],
        tags: [
          Tag(id: 'family', name: 'семья'),
          Tag(id: 'work', name: 'работа'),
        ],
      );

      controller.setSearchQuery('#семья');

      expect(controller.filteredQuotes.map((quote) => quote.id), ['q1']);
    });
  });

  group('QuoteController filters and sorting', () {
    test('filters entries by type and favorites', () {
      final controller = _controller(
        quotes: [
          _quote(
            id: 'q1',
            text: 'Quote',
            tagIds: const [],
            typeKey: QuoteType.quote.key,
            isFavorite: true,
          ),
          _quote(
            id: 'q2',
            text: 'Thought',
            tagIds: const [],
            typeKey: QuoteType.thought.key,
          ),
          _quote(
            id: 'q3',
            text: 'Excerpt',
            tagIds: const [],
            typeKey: QuoteType.excerpt.key,
            isFavorite: true,
          ),
        ],
        tags: const [],
      );

      controller.toggleTypeFilter(QuoteType.excerpt);
      expect(controller.filteredQuotes.map((quote) => quote.id), ['q3']);

      controller.toggleFavoritesOnly();
      expect(controller.filteredQuotes.map((quote) => quote.id), ['q3']);

      controller.clearFilters();
      expect(controller.filteredQuotes, hasLength(3));
      expect(
        controller.filteredQuotes.map((quote) => quote.id),
        containsAll(['q1', 'q2', 'q3']),
      );
    });

    test('sorts entries by created and updated dates', () {
      final controller = _controller(
        quotes: [
          _quote(
            id: 'old',
            text: 'Old',
            tagIds: const [],
            createdAt: DateTime(2026, 1, 1),
            updatedAt: DateTime(2026, 1, 5),
          ),
          _quote(
            id: 'new',
            text: 'New',
            tagIds: const [],
            createdAt: DateTime(2026, 1, 3),
            updatedAt: DateTime(2026, 1, 3),
          ),
          _quote(
            id: 'updated',
            text: 'Updated',
            tagIds: const [],
            createdAt: DateTime(2026, 1, 2),
            updatedAt: DateTime(2026, 1, 6),
          ),
        ],
        tags: const [],
      );

      expect(controller.filteredQuotes.map((quote) => quote.id), [
        'new',
        'updated',
        'old',
      ]);

      controller.setSortMode(QuoteSortMode.oldest);
      expect(controller.filteredQuotes.map((quote) => quote.id), [
        'old',
        'updated',
        'new',
      ]);

      controller.setSortMode(QuoteSortMode.updated);
      expect(controller.filteredQuotes.map((quote) => quote.id), [
        'updated',
        'old',
        'new',
      ]);
    });

    test('toggleFavorite persists favorite state in repository', () async {
      final repository = _MemoryQuoteRepository([
        _quote(id: 'q1', text: 'Entry', tagIds: const []),
      ]);
      final controller = QuoteController(
        quoteRepository: repository,
        tagRepository: _MemoryTagRepository(const []),
      )..loadInitial();

      await controller.toggleFavorite(controller.filteredQuotes.single);
      controller.refreshFromStorage();

      expect(repository.getAll().single.isFavorite, isTrue);
      expect(controller.filteredQuotes.single.isFavorite, isTrue);
    });
  });

  group('topic index', () {
    test('builds a nested tree and aggregates note counts', () {
      final topics = buildTopicIndex(
        quotes: [
          _quote(id: 'q1', text: 'one', tagIds: ['familyKids']),
          _quote(id: 'q2', text: 'two', tagIds: ['familyBudget']),
          _quote(id: 'q3', text: 'three', tagIds: ['familyKids']),
        ],
        tags: [
          Tag(id: 'familyKids', name: 'семья/дети'),
          Tag(id: 'familyBudget', name: 'семья/бюджет'),
        ],
        sortMode: TopicSortMode.alphabetic,
      );

      expect(topics.single.path, 'семья');
      expect(topics.single.count, 3);
      expect(topics.single.children.map((topic) => topic.path), [
        'семья/бюджет',
        'семья/дети',
      ]);
      expect(topics.single.children.map((topic) => topic.count), [1, 2]);
    });

    test('sorts popular topics by frequency', () {
      final topics = buildTopicIndex(
        quotes: [
          _quote(id: 'q1', text: 'one', tagIds: ['work']),
          _quote(id: 'q2', text: 'two', tagIds: ['family']),
          _quote(id: 'q3', text: 'three', tagIds: ['family']),
        ],
        tags: [
          Tag(id: 'work', name: 'работа'),
          Tag(id: 'family', name: 'семья'),
        ],
        sortMode: TopicSortMode.frequency,
      );

      expect(topics.map((topic) => topic.path), ['семья', 'работа']);
    });
  });
}

QuoteController _controller({
  required List<Quote> quotes,
  required List<Tag> tags,
}) {
  final controller = QuoteController(
    quoteRepository: _MemoryQuoteRepository(quotes),
    tagRepository: _MemoryTagRepository(tags),
  );
  controller.loadInitial();
  return controller;
}

Quote _quote({
  required String id,
  required String text,
  required List<String> tagIds,
  String typeKey = 'quote',
  DateTime? createdAt,
  DateTime? updatedAt,
  bool isFavorite = false,
}) {
  final date = DateTime(2026);
  return Quote(
    id: id,
    text: text,
    author: '',
    tagIds: tagIds,
    typeKey: typeKey,
    createdAt: createdAt ?? date,
    updatedAt: updatedAt ?? createdAt ?? date,
    isFavorite: isFavorite,
  );
}

class _MemoryQuoteRepository implements QuoteRepository {
  _MemoryQuoteRepository(List<Quote> quotes) : _quotes = [...quotes];

  final List<Quote> _quotes;

  @override
  List<Quote> getAll() => [..._quotes];

  @override
  Future<void> save(Quote quote) async {
    _quotes.removeWhere((item) => item.id == quote.id);
    _quotes.add(quote);
  }

  @override
  Future<void> deleteById(String id) async {
    _quotes.removeWhere((quote) => quote.id == id);
  }

  @override
  Stream<BoxEvent> watch() => const Stream<BoxEvent>.empty();
}

class _MemoryTagRepository implements TagRepository {
  _MemoryTagRepository(List<Tag> tags) : _tags = [...tags];

  final List<Tag> _tags;

  @override
  List<Tag> getAll() => [..._tags];

  @override
  Future<void> save(Tag tag) async {
    _tags.removeWhere((item) => item.id == tag.id);
    _tags.add(tag);
  }

  @override
  Stream<BoxEvent> watch() => const Stream<BoxEvent>.empty();
}
