import '../contollers/quote_contoller.dart';
import '../models/quote.dart';
import 'app_settings.dart';

class AppStrings {
  const AppStrings(this.language);

  final AppLanguage language;

  bool get isRu => language == AppLanguage.ru;

  String get appTitle => 'MEMRYTH';
  String get newEntry => isRu ? 'Новая запись' : 'New entry';
  String get sortTooltip => isRu ? 'Сортировка' : 'Sort';
  String get settings => isRu ? 'Настройки' : 'Settings';
  String get settingsSubtitle =>
      isRu ? 'Внешний вид и поведение приложения' : 'Visuals and behavior';
  String get languageTitle => isRu ? 'Язык' : 'Language';
  String get themeTitle => isRu ? 'Тема' : 'Theme';
  String get quoteTextTitle =>
      isRu ? 'Размер текста записи' : 'Entry text size';
  String get lineSpacingTitle => isRu ? 'Межстрочный интервал' : 'Line spacing';
  String get uiSizeTitle => isRu ? 'Размер интерфейса' : 'UI size';
  String get densityTitle => isRu ? 'Плотность карточек' : 'Card density';
  String get tagSizeTitle => isRu ? 'Размер тегов' : 'Tag size';
  String get collapsedTitle =>
      isRu ? 'Высота свернутой карточки' : 'Collapsed card height';
  String get defaultSortTitle =>
      isRu ? 'Сортировка по умолчанию' : 'Default sort';
  String get cardPreviewTitle =>
      isRu ? 'Показывать в карточке' : 'Show in cards';
  String get showNote => isRu ? 'Заметку' : 'Note';
  String get showMeta => isRu ? 'Автора и источник' : 'Author and source';
  String get favorites => isRu ? 'Избранное' : 'Favorites';
  String get emptyList => isRu
      ? 'Пока нет записей. Нажмите «Новая запись», чтобы добавить первую.'
      : 'No entries yet. Tap “New entry” to add your first one.';
  String get emptyFilter => isRu
      ? 'По текущим фильтрам ничего не найдено'
      : 'Nothing matches the current filter.';
  String get resetFilters => isRu ? 'Сбросить фильтры' : 'Reset filters';
  String get copied => isRu ? 'Запись скопирована' : 'Entry copied';
  String get deleteEntry => isRu ? 'Удалить запись?' : 'Delete entry?';
  String get deleteWarning =>
      isRu ? 'Это действие нельзя отменить.' : 'This action cannot be undone.';
  String get cancel => isRu ? 'Отмена' : 'Cancel';
  String get delete => isRu ? 'Удалить' : 'Delete';
  String get open => isRu ? 'Открыть' : 'Open';
  String get edit => isRu ? 'Редактировать' : 'Edit';
  String get copy => isRu ? 'Копировать' : 'Copy';
  String get searchHint => isRu
      ? 'Поиск по тексту, автору, источнику, заметке и тегам'
      : 'Search text, author, source, note and tags';
  String get tagNone => isRu ? 'Теги не добавлены' : 'No tags yet';
  String get hideTags => isRu ? 'Скрыть теги' : 'Hide tags';
  String showAllTags(int count) =>
      isRu ? 'Показать все теги ($count)' : 'Show all tags ($count)';
  String get collapse => isRu ? 'Свернуть' : 'Collapse';
  String get expand => isRu ? 'Развернуть' : 'Expand';
  String get myNote => isRu ? 'Моя заметка' : 'My note';
  String get createdAt => isRu ? 'Дата создания' : 'Created date';
  String get updatedAt => isRu ? 'Обновлено' : 'Updated at';
  String get changeDate => isRu ? 'Изменить дату' : 'Change date';
  String get details => isRu ? 'Подробнее' : 'Details';
  String get tags => isRu ? 'Теги' : 'Tags';
  String get addToFavorites => isRu ? 'В избранное' : 'Favorite';
  String get favoriteHint => isRu
      ? 'Быстрый доступ к самым важным записям'
      : 'Quick access to the most important entries';
  String get typeEntry => isRu ? 'Тип записи' : 'Entry type';
  String get entryTextThought => isRu ? 'Текст мысли' : 'Thought text';
  String get entryText => isRu ? 'Текст записи' : 'Entry text';
  String get hintExcerpt =>
      isRu ? 'Вставьте полный фрагмент текста' : 'Paste the full excerpt';
  String get hintEntry => isRu
      ? 'Сохраните текст, к которому хотите вернуться'
      : 'Save text you want to return to';
  String get authorOptional => isRu
      ? 'Автор / собеседник (необязательно)'
      : 'Author / speaker (optional)';
  String get author => isRu ? 'Автор' : 'Author';
  String get source => isRu ? 'Источник' : 'Source';
  String get sourceHint =>
      isRu ? 'Книга, статья, видео, лекция' : 'Book, article, video, lecture';
  String get sourceDetails => isRu ? 'Детали источника' : 'Source details';
  String get sourceDetailsHint =>
      isRu ? 'Глава, страница, таймкод' : 'Chapter, page, timestamp';
  String get note => isRu ? 'Моя заметка' : 'My note';
  String get noteHint => isRu
      ? 'Почему вы сохранили эту запись и как хотите ее использовать'
      : 'Why you saved this entry and how you want to use it';
  String get add => isRu ? 'Добавить' : 'Add';
  String get newTag => isRu ? 'Новый тег' : 'New tag';
  String get quickAddTags =>
      isRu ? 'Быстро добавить из существующих' : 'Quick add from existing tags';
  String get editTitle => isRu ? 'Редактирование' : 'Edit entry';
  String get createTitle => isRu ? 'Новая запись' : 'New entry';
  String get save => isRu ? 'Сохранить' : 'Save';
  String get exitWithoutSaving =>
      isRu ? 'Выйти без сохранения?' : 'Exit without saving?';
  String get changesLost => isRu
      ? 'Все несохраненные изменения будут потеряны.'
      : 'All unsaved changes will be lost.';
  String get stay => isRu ? 'Остаться' : 'Stay';
  String get exit => isRu ? 'Выйти' : 'Exit';
  String rows(int value) => isRu ? '$value строк' : '$value lines';

  String quoteTypeLabel(QuoteType type) => switch ((type, language)) {
    (QuoteType.quote, AppLanguage.ru) => 'Цитата',
    (QuoteType.thought, AppLanguage.ru) => 'Мысль',
    (QuoteType.excerpt, AppLanguage.ru) => 'Фрагмент',
    (QuoteType.quote, AppLanguage.en) => 'Quote',
    (QuoteType.thought, AppLanguage.en) => 'Thought',
    (QuoteType.excerpt, AppLanguage.en) => 'Excerpt',
  };

  String sortModeLabel(QuoteSortMode mode) => switch ((mode, language)) {
    (QuoteSortMode.newest, AppLanguage.ru) => 'Сначала новые',
    (QuoteSortMode.updated, AppLanguage.ru) => 'Недавно измененные',
    (QuoteSortMode.oldest, AppLanguage.ru) => 'Сначала старые',
    (QuoteSortMode.random, AppLanguage.ru) => 'Случайный порядок',
    (QuoteSortMode.newest, AppLanguage.en) => 'Newest first',
    (QuoteSortMode.updated, AppLanguage.en) => 'Recently updated',
    (QuoteSortMode.oldest, AppLanguage.en) => 'Oldest first',
    (QuoteSortMode.random, AppLanguage.en) => 'Random order',
  };
}
