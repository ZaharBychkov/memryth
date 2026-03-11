import '../contollers/quote_contoller.dart';

class QuoteListViewModel extends QuoteController {
  QuoteListViewModel({
    required super.quoteRepository,
    required super.tagRepository,
    super.initialSortMode,
  });
}
