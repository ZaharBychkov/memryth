import '../models/quote.dart';
import '../models/quote_sort_mode.dart';
import 'app_settings.dart';

class AppStrings {
  const AppStrings(this.language);

  final AppLanguage language;

  bool get isRu => language == AppLanguage.ru;

  String get appTitle => 'MEMRYTH';
  String get newEntry => isRu ? 'Новая запись' : 'New entry';
  String get sortTooltip => isRu ? 'Сортировка' : 'Sort';
  String get settings => isRu ? 'Настройки' : 'Settings';
  String get topicsTitle => isRu ? 'Темы' : 'Topics';
  String get topicsTooltip => isRu ? 'Индекс тем' : 'Topic index';
  String get themeAction => isRu ? 'Тема' : 'Theme';
  String get bulkActions => isRu ? 'Массовые' : 'Bulk';
  String get topicsEmpty => isRu
      ? 'Темы появятся после добавления записей. Добавляйте темы в форме записи, а потом нажимайте на них здесь, чтобы быстро фильтровать библиотеку.'
      : 'Topics appear after you add entries. Add topics in the entry form, then tap them here to filter your library.';
  String get topicSortAlphabetic => isRu ? 'А-Я' : 'A-Z';
  String get topicSortFrequency => isRu ? 'Популярные' : 'Popular';
  String get settingsSubtitle =>
      isRu ? 'Внешний вид и поведение приложения' : 'Visuals and behavior';
  String get languageTitle => isRu ? 'Язык' : 'Language';
  String get themeTitle => isRu ? 'Тема' : 'Theme';
  String get quoteTextTitle =>
      isRu ? 'Размер текста записи' : 'Entry text size';
  String get lineSpacingTitle => isRu ? 'Межстрочный интервал' : 'Line spacing';
  String get uiSizeTitle => isRu ? 'Размер интерфейса' : 'UI size';
  String get densityTitle => isRu ? 'Плотность карточек' : 'Card density';
  String get tagSizeTitle => isRu ? 'Размер тем' : 'Topic size';
  String get collapsedTitle =>
      isRu ? 'Высота свернутой карточки' : 'Collapsed card height';
  String get defaultSortTitle =>
      isRu ? 'Сортировка по умолчанию' : 'Default sort';
  String get cardPreviewTitle =>
      isRu ? 'Показывать в карточке' : 'Show in cards';
  String get showNote => isRu ? 'Заметку' : 'Note';
  String get showMeta => isRu ? 'Автора и источник' : 'Author and source';
  String get sourcePrefix => isRu ? 'в' : 'in';
  String get favorites => isRu ? 'Избранное' : 'Favorites';
  String get emptyLibraryTitle =>
      isRu ? 'Ваша библиотека пока пуста' : 'Your library is empty';
  String get emptyLibraryBody => isRu
      ? 'Сохраните первую мысль, цитату или фрагмент.'
      : 'Save your first thought, quote, or excerpt.';
  String get importBackup => isRu ? 'Импортировать backup' : 'Import backup';
  String get createFirstEntry =>
      isRu ? 'Создать первую запись' : 'Create first entry';
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
  String get select => isRu ? 'Выбрать' : 'Select';
  String get selectEntries => isRu ? 'Выбрать записи' : 'Select entries';
  String selectedEntries(int count) =>
      isRu ? 'Выбрано: $count' : '$count selected';
  String get exportSelected =>
      isRu ? 'Экспортировать выбранные' : 'Export selected';
  String get exportSelectedShareSubject =>
      isRu ? 'Выбранные записи MEMRYTH' : 'Selected MEMRYTH entries';
  String get exportSelectedShareText => isRu
      ? 'JSON-файл с выбранными записями MEMRYTH'
      : 'JSON file with selected MEMRYTH entries';
  String exportSelectedReady(int count) => isRu
      ? 'Экспортировано выбранных записей: $count'
      : 'Exported selected entries: $count';
  String get exportSelectedFailed =>
      isRu ? 'Не удалось экспортировать выбранные записи' : 'Export failed';
  String get addTopicsToSelected =>
      isRu ? 'Добавить темы к выбранным' : 'Add topics to selected';
  String get addSelectedTopicsToEntries => isRu
      ? 'Добавить выбранные темы к записям'
      : 'Add selected topics to entries';
  String get removeTopicsFromSelected =>
      isRu ? 'Убрать темы у выбранных' : 'Remove topics from selected';
  String get noTopicsToAssign =>
      isRu ? 'Сначала создайте хотя бы одну тему' : 'Create a topic first';
  String get chooseTopics => isRu ? 'Выберите темы' : 'Choose topics';
  String get existingTopics => isRu ? 'Существующие темы' : 'Existing topics';
  String get newTopicForSelected =>
      isRu ? 'Новая тема для выбранных' : 'New topic for selected';
  String topicsAddedToSelected(int count) =>
      isRu ? 'Темы добавлены к записям: $count' : 'Topics added to: $count';
  String topicsRemovedFromSelected(int count) =>
      isRu ? 'Темы убраны у записей: $count' : 'Topics removed from: $count';
  String get markSelectedFavorite =>
      isRu ? 'Добавить выбранные в избранное' : 'Favorite selected';
  String get unmarkSelectedFavorite =>
      isRu ? 'Убрать выбранные из избранного' : 'Unfavorite selected';
  String get deleteSelected => isRu ? 'Удалить выбранные' : 'Delete selected';
  String deleteSelectedTitle(int count) =>
      isRu ? 'Удалить $count записей?' : 'Delete $count entries?';
  String get deleteSelectedWarning =>
      isRu ? 'Это нельзя отменить.' : 'This cannot be undone.';
  String selectedDeleted(int count) =>
      isRu ? 'Удалено записей: $count' : 'Deleted entries: $count';
  String selectedFavoriteUpdated(int count, bool isFavorite) {
    if (isFavorite) {
      return isRu
          ? 'Добавлено в избранное: $count'
          : 'Added to favorites: $count';
    }
    return isRu
        ? 'Убрано из избранного: $count'
        : 'Removed from favorites: $count';
  }

  String get searchHint => isRu ? 'Поиск или #тема' : 'Search or #topic';
  String get tagNone => isRu ? 'Темы не добавлены' : 'No topics yet';
  String get hideTags => isRu ? 'Скрыть темы' : 'Hide topics';
  String showAllTags(int count) =>
      isRu ? 'Показать все темы ($count)' : 'Show all topics ($count)';
  String get collapse => isRu ? 'Свернуть' : 'Collapse';
  String get expand => isRu ? 'Развернуть' : 'Expand';
  String get myNote => isRu ? 'Моя заметка' : 'My note';
  String get createdAt => isRu ? 'Дата создания' : 'Created date';
  String get updatedAt => isRu ? 'Обновлено' : 'Updated at';
  String get changeDate => isRu ? 'Изменить дату' : 'Change date';
  String get details => isRu ? 'Подробнее' : 'Details';
  String get tags => isRu ? 'Темы' : 'Topics';
  String get allEntriesFilter => isRu ? 'Все' : 'All';
  String get addToFavorites => isRu ? 'В избранное' : 'Favorite';
  String get favoriteHint => isRu
      ? 'Быстрый доступ к самым важным записям'
      : 'Quick access to the most important entries';
  String get typeEntry => isRu ? 'Тип записи' : 'Entry type';
  String get contextSection => isRu ? 'Контекст' : 'Context';
  String entryTextLabel(QuoteType type) => switch ((type, language)) {
    (QuoteType.quote, AppLanguage.ru) => 'Текст цитаты *',
    (QuoteType.thought, AppLanguage.ru) => 'Текст мысли *',
    (QuoteType.excerpt, AppLanguage.ru) => 'Текст фрагмента *',
    (QuoteType.quote, AppLanguage.en) => 'Quote text *',
    (QuoteType.thought, AppLanguage.en) => 'Thought text *',
    (QuoteType.excerpt, AppLanguage.en) => 'Excerpt text *',
  };
  String get hintExcerpt =>
      isRu ? 'Вставьте полный фрагмент текста' : 'Paste the full excerpt';
  String get hintEntry => isRu
      ? 'Сохраните текст, к которому хотите вернуться'
      : 'Save text you want to return to';
  String get authorOptional =>
      isRu ? 'Автор, необязательно' : 'Author, optional';
  String get author => isRu ? 'Автор' : 'Author';
  String get source => isRu ? 'Источник' : 'Source';
  String get sourceOptional =>
      isRu ? 'Источник, необязательно' : 'Source, optional';
  String get sourceHint => isRu
      ? 'Книга, видео, статья, страница или ссылка'
      : 'Book, video, article, page, or link';
  String get note => isRu ? 'Моя заметка' : 'My note';
  String get noteOptional =>
      isRu ? 'Моя заметка, необязательно' : 'My note, optional';
  String get noteHint => isRu
      ? 'Почему вы сохранили эту запись и как хотите ее использовать'
      : 'Why you saved this entry and how you want to use it';
  String get add => isRu ? 'Добавить' : 'Add';
  String get addTopic => isRu ? 'Добавить тему' : 'Add topic';
  String get topicHelp => isRu
      ? 'Темы помогают группировать записи. Используйте / для вложенных тем, например книги/философия. Позже ищите #тема или откройте индекс тем сверху.'
      : 'Topics group entries. Use / for nested topics, for example books/philosophy. Later, search #topic or open the topic index above.';
  String get editTagsTitle => isRu ? 'Тема/тег' : 'Topic/tag';
  String get editNewTag =>
      isRu ? 'Тема/тег, необязательно' : 'Topic/tag, optional';
  String get editAddTag => isRu ? 'Добавить' : 'Add';
  String get newTag => isRu ? 'Новая тема' : 'New topic';
  String get quickAddTags => isRu
      ? 'Быстро добавить из существующих тем'
      : 'Quick add from existing topics';
  String get editTitle => isRu ? 'Редактирование' : 'Edit entry';
  String get createTitle => isRu ? 'Новая запись' : 'New entry';
  String get save => isRu ? 'Сохранить' : 'Save';
  String get saveChanges => isRu ? 'Сохранить изменения' : 'Save changes';
  String saveEntry(QuoteType type) {
    return switch ((type, language)) {
      (QuoteType.quote, AppLanguage.ru) => 'Сохранить цитату',
      (QuoteType.thought, AppLanguage.ru) => 'Сохранить мысль',
      (QuoteType.excerpt, AppLanguage.ru) => 'Сохранить фрагмент',
      (QuoteType.quote, AppLanguage.en) => 'Save quote',
      (QuoteType.thought, AppLanguage.en) => 'Save thought',
      (QuoteType.excerpt, AppLanguage.en) => 'Save excerpt',
    };
  }

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

  String quoteTypeFilterLabel(QuoteType type) => switch ((type, language)) {
    (QuoteType.quote, AppLanguage.ru) => 'Цитаты',
    (QuoteType.thought, AppLanguage.ru) => 'Мысли',
    (QuoteType.excerpt, AppLanguage.ru) => 'Фрагменты',
    (QuoteType.quote, AppLanguage.en) => 'Quotes',
    (QuoteType.thought, AppLanguage.en) => 'Thoughts',
    (QuoteType.excerpt, AppLanguage.en) => 'Excerpts',
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
