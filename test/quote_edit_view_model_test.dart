import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:memryth_dart_project/models/quote.dart';
import 'package:memryth_dart_project/models/tag.dart';
import 'package:memryth_dart_project/repositories/quote_repository.dart';
import 'package:memryth_dart_project/repositories/tag_repository.dart';
import 'package:memryth_dart_project/viewmodels/quote_edit_view_model.dart';

void main() {
  group('QuoteEditViewModel', () {
    test('canSave follows required entry text', () {
      final viewModel = QuoteEditViewModel(
        quoteRepository: _MemoryQuoteRepository(),
        tagRepository: _MemoryTagRepository(),
      );
      addTearDown(viewModel.dispose);

      expect(viewModel.canSave, isFalse);

      viewModel.textController.text = '  A quote  ';
      expect(viewModel.canSave, isTrue);

      viewModel.textController.clear();
      expect(viewModel.canSave, isFalse);
    });
  });
}

class _MemoryQuoteRepository implements QuoteRepository {
  @override
  List<Quote> getAll() => const [];

  @override
  Future<void> save(Quote quote) async {}

  @override
  Future<void> deleteById(String id) async {}

  @override
  Stream<BoxEvent> watch() => const Stream<BoxEvent>.empty();
}

class _MemoryTagRepository implements TagRepository {
  @override
  List<Tag> getAll() => const [];

  @override
  Future<void> save(Tag tag) async {}

  @override
  Stream<BoxEvent> watch() => const Stream<BoxEvent>.empty();
}
