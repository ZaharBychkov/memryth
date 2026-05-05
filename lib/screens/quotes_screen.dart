import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../contollers/quote_contoller.dart';
import '../models/quote.dart';
import '../models/tag.dart';
import '../repositories/quote_repository.dart';
import '../repositories/tag_repository.dart';
import '../services/export_import_service.dart';
import '../settings/app_settings_controller.dart';
import '../settings/app_settings_scope.dart';
import '../settings/app_strings.dart';
import '../viewmodels/topic_index.dart';
import '../viewmodels/quote_list_view_model.dart';
import '../widgets/quote_card.dart';
import '../widgets/search_bar.dart';
import 'quote_detail_screen.dart';
import 'quote_edit_screen.dart';
import 'settings_screen.dart';

class QuotesScreen extends StatefulWidget {
  const QuotesScreen({super.key});

  @override
  State<QuotesScreen> createState() => _QuotesScreenState();
}

class _QuotesScreenState extends State<QuotesScreen> {
  static const MethodChannel _shareChannel = MethodChannel(
    'app.memryth.android/share',
  );

  final QuoteRepository _quoteRepository = HiveQuoteRepository();
  final TagRepository _tagRepository = HiveTagRepository();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  QuoteListViewModel? _controller;
  StreamSubscription<dynamic>? _quotesSub;
  StreamSubscription<dynamic>? _tagsSub;
  bool _selectionMode = false;
  bool _selectionBusy = false;
  final Set<String> _selectedQuoteIds = <String>{};

  @override
  void initState() {
    super.initState();
    _quotesSub = _quoteRepository.watch().listen((_) => _onStorageChanged());
    _tagsSub = _tagRepository.watch().listen((_) => _onStorageChanged());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _bindShareTarget();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = AppSettingsScope.of(context).settings;
    _controller ??= QuoteListViewModel(
      quoteRepository: _quoteRepository,
      tagRepository: _tagRepository,
      initialSortMode: settings.defaultSortMode,
    )..loadInitial();

    if (_controller!.sortMode != settings.defaultSortMode) {
      _controller!.setSortMode(settings.defaultSortMode);
    }
  }

  @override
  void dispose() {
    _quotesSub?.cancel();
    _tagsSub?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsController = AppSettingsScope.of(context);
    final strings = AppStrings(settingsController.settings.language);
    final controller = _controller;
    if (controller == null) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerBg = isDark ? const Color(0xFF1A1E24) : const Color(0xFFF5F0E6);

    return AnimatedBuilder(
      animation: Listenable.merge([controller, settingsController]),
      builder: (context, _) {
        final filtered = controller.filteredQuotes;
        final hasAnyQuotes = controller.totalCount > 0;

        return Scaffold(
          floatingActionButton: _selectionMode || !hasAnyQuotes
              ? null
              : FloatingActionButton.extended(
                  onPressed: _openCreate,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.add),
                  label: Text(strings.newEntry),
                ),
          appBar: _selectionMode
              ? _buildSelectionAppBar(controller, strings)
              : AppBar(
                  centerTitle: true,
                  title: Text(
                    strings.appTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  actions: [
                    if (!hasAnyQuotes)
                      IconButton(
                        tooltip: strings.settings,
                        onPressed: () => _openSettings(settingsController),
                        icon: const Icon(Icons.tune_rounded),
                      ),
                  ],
                ),
          body: SafeArea(
            child: Column(
              children: [
                if (hasAnyQuotes)
                  Container(
                    width: double.infinity,
                    color: headerBg,
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: Column(
                      children: [
                        _buildActionStrip(
                          controller,
                          settingsController,
                          strings,
                          isDark,
                        ),
                        const SizedBox(height: 10),
                        QuoteSearchBar(
                          controller: _searchController,
                          hintText: strings.searchHint,
                          onChanged: controller.setSearchQuery,
                          onClear: () {
                            _searchController.clear();
                            controller.setSearchQuery('');
                          },
                        ),
                        const SizedBox(height: 10),
                        _buildTypeFiltersRow(controller, strings),
                      ],
                    ),
                  ),
                Expanded(
                  child: filtered.isEmpty
                      ? _buildEmptyState(
                          controller,
                          strings,
                          settingsController,
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          physics: const ClampingScrollPhysics(),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          cacheExtent: 500,
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final quote = filtered[index];
                            return RepaintBoundary(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  bottom:
                                      settingsController.settings.cardSpacing,
                                ),
                                child: QuoteCard(
                                  quote: quote,
                                  tags: controller.tagsForQuote(quote),
                                  query: controller.searchQuery,
                                  activeTagFilters: controller.activeTagFilters,
                                  onTagTap: controller.toggleTagFilter,
                                  selectionMode: _selectionMode,
                                  selected: _selectedQuoteIds.contains(
                                    quote.id,
                                  ),
                                  onTap: () => _selectionMode
                                      ? _toggleQuoteSelection(quote)
                                      : _openDetails(quote),
                                  onFavoriteToggle: () => _selectionMode
                                      ? _toggleQuoteSelection(quote)
                                      : controller.toggleFavorite(quote),
                                  onLongPressStart: (details) {
                                    if (_selectionMode) {
                                      _toggleQuoteSelection(quote);
                                      return;
                                    }
                                    _showQuoteMenu(quote, details, strings);
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildSelectionAppBar(
    QuoteController controller,
    AppStrings strings,
  ) {
    final selectedCount = _selectedQuotes(controller).length;
    final hasSelection = selectedCount > 0;
    final actionsEnabled = hasSelection && !_selectionBusy;

    return AppBar(
      centerTitle: false,
      titleSpacing: 0,
      leading: IconButton(
        tooltip: strings.cancel,
        onPressed: _exitSelectionMode,
        icon: const Icon(Icons.close_rounded),
      ),
      title: Text(
        strings.selectedEntries(selectedCount),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      actions: [
        if (_selectionBusy)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else
          PopupMenuButton<_SelectionAction>(
            tooltip: strings.bulkActions,
            enabled: actionsEnabled,
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF232830)
                : const Color(0xFFF5EEE7),
            surfaceTintColor: Colors.transparent,
            elevation: 10,
            position: PopupMenuPosition.under,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1.2,
              ),
            ),
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (action) =>
                _handleSelectionAction(action, controller, strings),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _SelectionAction.export,
                child: _SelectionMenuItem(
                  icon: Icons.ios_share_rounded,
                  label: strings.exportSelected,
                ),
              ),
              PopupMenuItem(
                value: _SelectionAction.addTopics,
                child: _SelectionMenuItem(
                  icon: Icons.label_rounded,
                  label: strings.addTopicsToSelected,
                ),
              ),
              PopupMenuItem(
                value: _SelectionAction.removeTopics,
                child: _SelectionMenuItem(
                  icon: Icons.label_off_rounded,
                  label: strings.removeTopicsFromSelected,
                ),
              ),
              PopupMenuItem(
                value: _SelectionAction.favorite,
                child: _SelectionMenuItem(
                  icon: Icons.star_rounded,
                  label: strings.markSelectedFavorite,
                ),
              ),
              PopupMenuItem(
                value: _SelectionAction.unfavorite,
                child: _SelectionMenuItem(
                  icon: Icons.star_border_rounded,
                  label: strings.unmarkSelectedFavorite,
                ),
              ),
            ],
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  void _handleSelectionAction(
    _SelectionAction action,
    QuoteController controller,
    AppStrings strings,
  ) {
    switch (action) {
      case _SelectionAction.export:
        _exportSelected(controller, strings);
        break;
      case _SelectionAction.addTopics:
        _addTagsToSelected(controller, strings);
        break;
      case _SelectionAction.removeTopics:
        _removeTagsFromSelected(controller, strings);
        break;
      case _SelectionAction.favorite:
        _setSelectedFavorites(controller, true, strings);
        break;
      case _SelectionAction.unfavorite:
        _setSelectedFavorites(controller, false, strings);
        break;
    }
  }

  Widget _buildTypeFiltersRow(QuoteController controller, AppStrings strings) {
    return Row(
      children: [
        Expanded(
          child: _TypeFilterButton(
            label: strings.allEntriesFilter,
            selected:
                controller.activeTypeFilters.isEmpty &&
                !controller.favoritesOnly,
            onTap: controller.clearTypeAndFavoriteFilters,
          ),
        ),
        const SizedBox(width: 8),
        for (final type in QuoteType.values) ...[
          Expanded(
            child: _TypeFilterButton(
              label: strings.quoteTypeFilterLabel(type),
              selected: controller.activeTypeFilters.contains(type),
              onTap: () => controller.toggleTypeFilter(type),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: _TypeFilterButton(
            label: '★',
            selected: controller.favoritesOnly,
            onTap: controller.toggleFavoritesOnly,
          ),
        ),
      ],
    );
  }

  Widget _buildActionStrip(
    QuoteController controller,
    AppSettingsController settingsController,
    AppStrings strings,
    bool isDark,
  ) {
    return Row(
      children: [
        Expanded(
          child: PopupMenuButton<QuoteSortMode>(
            tooltip: strings.sortTooltip,
            initialValue: controller.sortMode,
            onSelected: controller.setSortMode,
            color: isDark ? const Color(0xFF232830) : const Color(0xFFF5EEE7),
            surfaceTintColor: Colors.transparent,
            elevation: 10,
            position: PopupMenuPosition.under,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1.2,
              ),
            ),
            itemBuilder: (context) => [
              for (final mode in QuoteSortMode.values)
                PopupMenuItem(
                  value: mode,
                  child: _SortMenuItem(
                    label: strings.sortModeLabel(mode),
                    selected: mode == controller.sortMode,
                  ),
                ),
            ],
            child: _ActionStripItem(
              icon: Icons.sort_rounded,
              label: strings.sortTooltip,
              isDark: isDark,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionStripButton(
            icon: Icons.checklist_rounded,
            label: strings.bulkActions,
            tooltip: strings.selectEntries,
            isDark: isDark,
            enabled: controller.totalCount > 0,
            onTap: _enterSelectionMode,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionStripButton(
            icon: Icons.account_tree_rounded,
            label: strings.topicsTitle,
            tooltip: strings.topicsTooltip,
            isDark: isDark,
            onTap: () => _openTopics(controller, strings),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionStripButton(
            icon: settingsController.settings.isDarkMode
                ? Icons.light_mode_rounded
                : Icons.dark_mode_rounded,
            label: strings.themeAction,
            isDark: isDark,
            onTap: settingsController.toggleTheme,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionStripButton(
            icon: Icons.tune_rounded,
            label: strings.settings,
            isDark: isDark,
            onTap: () => _openSettings(settingsController),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(
    QuoteController controller,
    AppStrings strings,
    AppSettingsController settingsController,
  ) {
    if (controller.totalCount == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_stories_rounded,
                size: 44,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 14),
              Text(
                strings.emptyLibraryTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                strings.emptyLibraryBody,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).hintColor,
                  fontSize: 15,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _openCreate,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(strings.createFirstEntry),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openDataSettings(settingsController),
                  icon: const Icon(Icons.file_download_rounded),
                  label: Text(strings.importBackup),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(strings.emptyFilter, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () {
              _searchController.clear();
              controller.clearFilters();
            },
            child: Text(strings.resetFilters),
          ),
        ],
      ),
    );
  }

  Future<void> _showQuoteMenu(
    Quote quote,
    LongPressStartDetails details,
    AppStrings strings,
  ) async {
    final action = await showGeneralDialog<String>(
      context: context,
      barrierLabel: 'quote-actions',
      barrierDismissible: true,
      barrierColor: const Color(0x22000000),
      transitionDuration: const Duration(milliseconds: 140),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _QuoteActionMenu(
          anchor: details.globalPosition,
          strings: strings,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );

    if (!mounted || action == null) {
      return;
    }
    if (action == 'read') {
      await _openDetails(quote);
      return;
    }
    if (action == 'edit') {
      await _openEdit(quote);
      return;
    }
    if (action == 'copy') {
      await _copyQuoteToClipboard(quote, strings);
      return;
    }
    if (action == 'select') {
      _enterSelectionMode(quote);
      return;
    }
    if (action == 'delete') {
      await _deleteQuote(quote.id, strings);
    }
  }

  void _enterSelectionMode([Quote? quote]) {
    setState(() {
      _selectionMode = true;
      if (quote != null) {
        _selectedQuoteIds.add(quote.id);
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectionBusy = false;
      _selectedQuoteIds.clear();
    });
  }

  void _toggleQuoteSelection(Quote quote) {
    setState(() {
      if (_selectedQuoteIds.contains(quote.id)) {
        _selectedQuoteIds.remove(quote.id);
      } else {
        _selectedQuoteIds.add(quote.id);
      }
    });
  }

  List<Quote> _selectedQuotes(QuoteController controller) {
    return controller.allQuotes
        .where((quote) => _selectedQuoteIds.contains(quote.id))
        .toList(growable: false);
  }

  Future<void> _setSelectedFavorites(
    QuoteController controller,
    bool isFavorite,
    AppStrings strings,
  ) async {
    if (_selectionBusy) {
      return;
    }

    final selected = _selectedQuotes(controller);
    if (selected.isEmpty) {
      return;
    }

    setState(() => _selectionBusy = true);
    await controller.setFavorites(selected, isFavorite);
    if (!mounted) {
      return;
    }

    _exitSelectionMode();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            strings.selectedFavoriteUpdated(selected.length, isFavorite),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  Future<void> _exportSelected(
    QuoteController controller,
    AppStrings strings,
  ) async {
    if (_selectionBusy) {
      return;
    }

    final selected = _selectedQuotes(controller);
    if (selected.isEmpty) {
      return;
    }

    setState(() => _selectionBusy = true);
    try {
      final service = ExportImportService(
        quoteRepository: _quoteRepository,
        tagRepository: _tagRepository,
      );
      final file = await service.writeExportFile(
        quotes: selected,
        fileNamePrefix: 'memryth-selected',
      );
      if (!mounted) {
        return;
      }

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/json')],
          subject: strings.exportSelectedShareSubject,
          text: strings.exportSelectedShareText,
          fileNameOverrides: [file.uri.pathSegments.last],
        ),
      );
      if (!mounted) {
        return;
      }

      _exitSelectionMode();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(strings.exportSelectedReady(selected.length)),
            duration: const Duration(seconds: 2),
          ),
        );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _selectionBusy = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(strings.exportSelectedFailed),
            duration: const Duration(seconds: 3),
          ),
        );
    }
  }

  Future<void> _addTagsToSelected(
    QuoteController controller,
    AppStrings strings,
  ) async {
    if (_selectionBusy) {
      return;
    }

    final selected = _selectedQuotes(controller);
    if (selected.isEmpty) {
      return;
    }
    final request = await _askTagsToAssign(
      controller,
      strings,
      title: strings.addTopicsToSelected,
      actionLabel: strings.save,
      allowNewTopic: true,
    );
    if (request == null || !request.hasSelection) {
      return;
    }

    setState(() => _selectionBusy = true);
    await controller.addTagIdsAndNamesToQuotes(
      selected,
      tagIds: request.tagIds,
      tagNames: request.newTagNames,
    );
    if (!mounted) {
      return;
    }

    _exitSelectionMode();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(strings.topicsAddedToSelected(selected.length)),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  Future<void> _removeTagsFromSelected(
    QuoteController controller,
    AppStrings strings,
  ) async {
    if (_selectionBusy) {
      return;
    }

    final selected = _selectedQuotes(controller);
    if (selected.isEmpty) {
      return;
    }

    final tagIdsInSelection = selected
        .expand((quote) => quote.tagIds)
        .toSet()
        .where((id) => controller.allTagsSorted.any((tag) => tag.id == id))
        .toSet();
    if (tagIdsInSelection.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(strings.noTopicsToAssign),
            duration: const Duration(seconds: 2),
          ),
        );
      return;
    }

    final request = await _askTagsToAssign(
      controller,
      strings,
      title: strings.removeTopicsFromSelected,
      actionLabel: strings.removeTopicsFromSelected,
      allowedTagIds: tagIdsInSelection,
    );
    if (request == null || request.tagIds.isEmpty) {
      return;
    }

    setState(() => _selectionBusy = true);
    await controller.removeTagsFromQuotes(selected, request.tagIds);
    if (!mounted) {
      return;
    }

    _exitSelectionMode();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(strings.topicsRemovedFromSelected(selected.length)),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  Future<_BulkTopicRequest?> _askTagsToAssign(
    QuoteController controller,
    AppStrings strings, {
    String? title,
    String? actionLabel,
    Set<String>? allowedTagIds,
    bool allowNewTopic = false,
  }) async {
    final availableTags = controller.allTagsSorted
        .where((tag) => allowedTagIds == null || allowedTagIds.contains(tag.id))
        .toList(growable: false);
    return showDialog<_BulkTopicRequest>(
      context: context,
      builder: (_) => _BulkTopicDialog(
        strings: strings,
        title: title ?? strings.chooseTopics,
        actionLabel: actionLabel ?? strings.add,
        availableTags: availableTags,
        allowNewTopic: allowNewTopic,
      ),
    );
  }

  Future<void> _copyQuoteToClipboard(Quote quote, AppStrings strings) async {
    final buffer = StringBuffer(quote.text.trim());
    if (quote.author.trim().isNotEmpty) {
      buffer.write('\n- ${quote.author.trim()}');
    }
    if (quote.sourceTitle.trim().isNotEmpty) {
      buffer.write('\n${quote.sourceTitle.trim()}');
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(strings.copied),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  Future<void> _openCreate({String initialText = ''}) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuoteEditScreen(
          quoteRepository: _quoteRepository,
          tagRepository: _tagRepository,
          initialText: initialText,
        ),
      ),
    );
  }

  Future<void> _bindShareTarget() async {
    _shareChannel.setMethodCallHandler((call) async {
      if (call.method == 'sharedText' && call.arguments is String) {
        await _openSharedText(call.arguments as String);
        return;
      }
      if (call.method == 'quickAdd') {
        await _openCreate();
      }
    });

    try {
      final initialText = await _shareChannel.invokeMethod<String>(
        'consumeInitialText',
      );
      if (initialText != null) {
        await _openSharedText(initialText);
        return;
      }

      final shouldQuickAdd = await _shareChannel.invokeMethod<bool>(
        'consumeQuickAdd',
      );
      if (shouldQuickAdd == true && mounted) {
        await _openCreate();
      }
    } on MissingPluginException {
      return;
    }
  }

  Future<void> _openSharedText(String value) async {
    final text = value.trim();
    if (text.isEmpty || !mounted) {
      return;
    }
    await _openCreate(initialText: text);
  }

  Future<void> _openEdit(Quote quote) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuoteEditScreen(
          quoteRepository: _quoteRepository,
          tagRepository: _tagRepository,
          quote: quote,
        ),
      ),
    );
  }

  Future<void> _openDetails(Quote quote) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuoteDetailScreen(
          quote: quote,
          tags: _controller!.tagsForQuote(quote),
          quoteRepository: _quoteRepository,
          tagRepository: _tagRepository,
        ),
      ),
    );
  }

  Future<void> _deleteQuote(String quoteId, AppStrings strings) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(strings.deleteEntry),
          content: Text(strings.deleteWarning),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(strings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB84A3A),
                foregroundColor: Colors.white,
              ),
              child: Text(strings.delete),
            ),
          ],
        );
      },
    );

    if (approved == true) {
      await _quoteRepository.deleteById(quoteId);
    }
  }

  void _onStorageChanged() {
    final controller = _controller;
    controller?.refreshFromStorage();
    if (controller == null || !_selectionMode) {
      return;
    }

    final currentIds = controller.allQuotes.map((quote) => quote.id).toSet();
    final beforeCount = _selectedQuoteIds.length;
    _selectedQuoteIds.removeWhere((id) => !currentIds.contains(id));
    if (mounted && beforeCount != _selectedQuoteIds.length) {
      setState(() {});
    }
  }

  Future<void> _openSettings(AppSettingsController settingsController) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsScreen(controller: settingsController),
      ),
    );
  }

  Future<void> _openDataSettings(
    AppSettingsController settingsController,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DataSettingsScreen(controller: settingsController),
      ),
    );
  }

  Future<void> _openTopics(
    QuoteController controller,
    AppStrings strings,
  ) async {
    final selectedTopic = await showGeneralDialog<String>(
      context: context,
      barrierLabel: 'topics-panel',
      barrierDismissible: true,
      barrierColor: const Color(0x33000000),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _TopicIndexPanel(controller: controller, strings: strings);
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );

    if (!mounted || selectedTopic == null) {
      return;
    }

    final query = '#$selectedTopic';
    _searchController.value = TextEditingValue(
      text: query,
      selection: TextSelection.collapsed(offset: query.length),
    );
    controller.setSearchQuery(query);
    if (_scrollController.hasClients) {
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
      );
    }
  }
}

class _ActionStripButton extends StatelessWidget {
  const _ActionStripButton({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
    this.enabled = true,
    this.tooltip,
  });

  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;
  final bool enabled;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(14),
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: _ActionStripItem(icon: icon, label: label, isDark: isDark),
      ),
    );
    if (tooltip == null) {
      return button;
    }
    return Tooltip(message: tooltip!, child: button);
  }
}

class _ActionStripItem extends StatelessWidget {
  const _ActionStripItem({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final foreground = isDark
        ? const Color(0xFFEAE4DB)
        : const Color(0xFF4E4035);
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262B33) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 19, color: foreground),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: foreground,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicIndexPanel extends StatefulWidget {
  const _TopicIndexPanel({required this.controller, required this.strings});

  final QuoteController controller;
  final AppStrings strings;

  @override
  State<_TopicIndexPanel> createState() => _TopicIndexPanelState();
}

class _TopicIndexPanelState extends State<_TopicIndexPanel> {
  TopicSortMode _sortMode = TopicSortMode.frequency;
  final Set<String> _expandedPaths = <String>{};

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screen = MediaQuery.sizeOf(context);
    final panelWidth = screen.width < 520 ? screen.width * 0.92 : 420.0;
    final topics = buildTopicIndex(
      quotes: widget.controller.allQuotes,
      tags: widget.controller.allTagsSorted,
      sortMode: _sortMode,
    );

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Align(
          alignment: Alignment.centerRight,
          child: Container(
            width: panelWidth,
            height: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F242B) : const Color(0xFFF8F3EA),
              border: Border(
                left: BorderSide(color: Theme.of(context).dividerColor),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x26000000),
                  blurRadius: 24,
                  offset: Offset(-6, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 10, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.strings.topicsTitle,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _TopicSortButton(
                          label: widget.strings.topicSortFrequency,
                          selected: _sortMode == TopicSortMode.frequency,
                          onTap: () => setState(
                            () => _sortMode = TopicSortMode.frequency,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _TopicSortButton(
                          label: widget.strings.topicSortAlphabetic,
                          selected: _sortMode == TopicSortMode.alphabetic,
                          onTap: () => setState(
                            () => _sortMode = TopicSortMode.alphabetic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: topics.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              widget.strings.topicsEmpty,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(context).hintColor,
                              ),
                            ),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                          children: [
                            for (final topic in topics) _buildTopic(topic, 0),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopic(TopicIndexNode topic, int depth) {
    final hasChildren = topic.children.isNotEmpty;
    final expanded = _expandedPaths.contains(topic.path);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TopicRow(
          topic: topic,
          depth: depth,
          expanded: expanded,
          hasChildren: hasChildren,
          onExpand: () {
            setState(() {
              if (expanded) {
                _expandedPaths.remove(topic.path);
              } else {
                _expandedPaths.add(topic.path);
              }
            });
          },
          onSelected: () => Navigator.of(context).pop(topic.path),
        ),
        if (hasChildren && expanded)
          for (final child in topic.children) _buildTopic(child, depth + 1),
      ],
    );
  }
}

class _TopicSortButton extends StatelessWidget {
  const _TopicSortButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(
                  context,
                ).colorScheme.primary.withAlpha(isDark ? 56 : 34)
              : (isDark ? const Color(0xFF262B33) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).dividerColor,
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).textTheme.bodyMedium?.color,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _TopicRow extends StatelessWidget {
  const _TopicRow({
    required this.topic,
    required this.depth,
    required this.expanded,
    required this.hasChildren,
    required this.onExpand,
    required this.onSelected,
  });

  final TopicIndexNode topic;
  final int depth;
  final bool expanded;
  final bool hasChildren;
  final VoidCallback onExpand;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? const Color(0xFFB8AEA2) : const Color(0xFF8B7E74);

    return Padding(
      padding: EdgeInsets.only(left: depth * 18.0, bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onSelected,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.fromLTRB(4, 4, 10, 4),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  height: 36,
                  child: hasChildren
                      ? IconButton(
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          onPressed: onExpand,
                          icon: Icon(
                            expanded
                                ? Icons.keyboard_arrow_down_rounded
                                : Icons.chevron_right_rounded,
                            color: muted,
                          ),
                        )
                      : Icon(Icons.tag_rounded, size: 16, color: muted),
                ),
                Expanded(
                  child: Text(
                    topic.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  constraints: const BoxConstraints(minWidth: 30),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF262B33)
                        : const Color(0xFFF0E8DD),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    topic.count.toString(),
                    style: TextStyle(
                      color: muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeFilterButton extends StatelessWidget {
  const _TypeFilterButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(
                  context,
                ).colorScheme.primary.withAlpha(isDark ? 56 : 36)
              : (isDark ? const Color(0xFF262B33) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).dividerColor,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuoteActionMenu extends StatelessWidget {
  const _QuoteActionMenu({required this.anchor, required this.strings});

  final Offset anchor;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    const menuWidth = 220.0;
    const menuHeight = 260.0;
    const margin = 12.0;
    const gapToAnchor = 14.0;
    const arrowSize = 12.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark
        ? const Color(0xFF232830)
        : const Color(0xFFF5EEE7);

    final showOnRight = anchor.dx < (screen.width / 2);
    var left = showOnRight
        ? anchor.dx + gapToAnchor
        : anchor.dx - menuWidth - gapToAnchor;
    left = left.clamp(margin, screen.width - menuWidth - margin);

    var top = anchor.dy - (menuHeight / 2);
    top = top.clamp(margin, screen.height - menuHeight - margin);

    var arrowTop = anchor.dy - top - (arrowSize / 2);
    arrowTop = arrowTop.clamp(16.0, menuHeight - 16.0 - arrowSize);

    final arrowLeft = showOnRight ? left - arrowSize + 1 : left + menuWidth - 1;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              behavior: HitTestBehavior.opaque,
            ),
          ),
          Positioned(
            left: arrowLeft,
            top: top + arrowTop,
            child: CustomPaint(
              size: const Size(12, 12),
              painter: _MenuArrowPainter(
                color: background,
                pointLeft: !showOnRight,
              ),
            ),
          ),
          Positioned(
            left: left,
            top: top,
            child: Container(
              width: menuWidth,
              height: menuHeight,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                  width: 1.2,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _MenuItem(
                    label: strings.open,
                    onTap: () => Navigator.of(context).pop('read'),
                    isTop: true,
                  ),
                  const _DividerLine(),
                  _MenuItem(
                    label: strings.edit,
                    onTap: () => Navigator.of(context).pop('edit'),
                  ),
                  const _DividerLine(),
                  _MenuItem(
                    label: strings.copy,
                    onTap: () => Navigator.of(context).pop('copy'),
                  ),
                  const _DividerLine(),
                  _MenuItem(
                    label: strings.select,
                    onTap: () => Navigator.of(context).pop('select'),
                  ),
                  const _DividerLine(),
                  _MenuItem(
                    label: strings.delete,
                    onTap: () => Navigator.of(context).pop('delete'),
                    isBottom: true,
                    color: const Color(0xFFB84A3A),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _SelectionAction { export, addTopics, removeTopics, favorite, unfavorite }

class _SelectionMenuItem extends StatelessWidget {
  const _SelectionMenuItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 12),
        Flexible(child: Text(label)),
      ],
    );
  }
}

class _BulkTopicRequest {
  const _BulkTopicRequest({required this.tagIds, required this.newTagNames});

  final Set<String> tagIds;
  final Set<String> newTagNames;

  bool get hasSelection => tagIds.isNotEmpty || newTagNames.isNotEmpty;
}

class _BulkTopicDialog extends StatefulWidget {
  const _BulkTopicDialog({
    required this.strings,
    required this.title,
    required this.actionLabel,
    required this.availableTags,
    required this.allowNewTopic,
  });

  final AppStrings strings;
  final String title;
  final String actionLabel;
  final List<Tag> availableTags;
  final bool allowNewTopic;

  @override
  State<_BulkTopicDialog> createState() => _BulkTopicDialogState();
}

class _BulkTopicDialogState extends State<_BulkTopicDialog> {
  final TextEditingController _newTopicController = TextEditingController();
  final Set<String> _selectedTagIds = <String>{};
  final Set<String> _newTopicNames = <String>{};

  Map<String, Tag> get _tagsByName => {
    for (final tag in widget.availableTags) tag.name.trim().toLowerCase(): tag,
  };

  bool get _canSubmit => _requestFromState().hasSelection;

  @override
  void dispose() {
    _newTopicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? const Color(0xFF262B33) : Colors.white;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Theme.of(context).dividerColor, width: 1.5),
    );
    final selectedExistingTags = widget.availableTags
        .where((tag) => _selectedTagIds.contains(tag.id))
        .toList(growable: false);

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.62,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.allowNewTopic) ...[
                  if (selectedExistingTags.isNotEmpty ||
                      _newTopicNames.isNotEmpty) ...[
                    Text(
                      widget.strings.tags,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final tag in selectedExistingTags)
                          InputChip(
                            label: Text(tag.name),
                            side: BorderSide(
                              color: Theme.of(context).dividerColor,
                              width: 1.2,
                            ),
                            backgroundColor: isDark
                                ? const Color(0xFF262B33)
                                : const Color(0xFFF5EEE7),
                            onDeleted: () =>
                                setState(() => _selectedTagIds.remove(tag.id)),
                          ),
                        for (final name in _newTopicNames)
                          InputChip(
                            label: Text(name),
                            side: BorderSide(
                              color: Theme.of(context).dividerColor,
                              width: 1.2,
                            ),
                            backgroundColor: isDark
                                ? const Color(0xFF262B33)
                                : const Color(0xFFF5EEE7),
                            onDeleted: () =>
                                setState(() => _newTopicNames.remove(name)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: _newTopicController,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _addTopicFromInput(),
                    decoration: _inputDecoration(
                      context: context,
                      border: border,
                      fillColor: fillColor,
                      labelText: widget.strings.newTag,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _newTopicController.text.trim().isNotEmpty
                          ? _addTopicFromInput
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF4A6FA5),
                        foregroundColor: Colors.white,
                      ),
                      child: Text(widget.strings.addTopic),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
                if (widget.availableTags.isNotEmpty) ...[
                  Text(
                    widget.allowNewTopic
                        ? widget.strings.quickAddTags
                        : widget.strings.existingTopics,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final tag in widget.availableTags)
                        FilterChip(
                          label: Text(tag.name),
                          selected: _selectedTagIds.contains(tag.id),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedTagIds.add(tag.id);
                              } else {
                                _selectedTagIds.remove(tag.id);
                              }
                            });
                          },
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.strings.cancel),
        ),
        FilledButton(
          onPressed: _canSubmit ? _submit : null,
          child: Text(widget.actionLabel),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required BuildContext context,
    required OutlineInputBorder border,
    required Color fillColor,
    required String labelText,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(
        color: isDark ? const Color(0xFFB8AEA2) : const Color(0xFF8B7E74),
      ),
      fillColor: fillColor,
      filled: true,
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 1.6,
        ),
      ),
    );
  }

  void _addTopicFromInput() {
    final name = _newTopicController.text.trim();
    if (name.isEmpty) {
      return;
    }

    final normalized = name.toLowerCase();
    final existingTag = _tagsByName[normalized];
    setState(() {
      if (existingTag != null) {
        _selectedTagIds.add(existingTag.id);
      } else if (!_newTopicNames.any(
        (topic) => topic.toLowerCase() == normalized,
      )) {
        _newTopicNames.add(name);
      }
      _newTopicController.clear();
    });
  }

  _BulkTopicRequest _requestFromState() {
    final tagIds = {..._selectedTagIds};
    final tagNames = {..._newTopicNames};
    final inputName = _newTopicController.text.trim();

    if (widget.allowNewTopic && inputName.isNotEmpty) {
      final normalized = inputName.toLowerCase();
      final existingTag = _tagsByName[normalized];
      if (existingTag != null) {
        tagIds.add(existingTag.id);
      } else if (!tagNames.any((topic) => topic.toLowerCase() == normalized)) {
        tagNames.add(inputName);
      }
    }

    return _BulkTopicRequest(tagIds: tagIds, newTagNames: tagNames);
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(_requestFromState());
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.label,
    required this.onTap,
    this.color,
    this.isTop = false,
    this.isBottom = false,
  });

  final String label;
  final VoidCallback onTap;
  final Color? color;
  final bool isTop;
  final bool isBottom;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.vertical(
          top: isTop ? const Radius.circular(16) : Radius.zero,
          bottom: isBottom ? const Radius.circular(16) : Radius.zero,
        ),
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: color ?? Theme.of(context).textTheme.bodyLarge?.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _DividerLine extends StatelessWidget {
  const _DividerLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 22),
      color: Theme.of(context).dividerColor,
    );
  }
}

class _SortMenuItem extends StatelessWidget {
  const _SortMenuItem({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
        if (selected)
          Icon(
            Icons.check_rounded,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
      ],
    );
  }
}

class _MenuArrowPainter extends CustomPainter {
  _MenuArrowPainter({required this.color, required this.pointLeft});

  final Color color;
  final bool pointLeft;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();

    if (pointLeft) {
      path
        ..moveTo(size.width, 0)
        ..lineTo(0, size.height / 2)
        ..lineTo(size.width, size.height)
        ..close();
    } else {
      path
        ..moveTo(0, 0)
        ..lineTo(size.width, size.height / 2)
        ..lineTo(0, size.height)
        ..close();
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MenuArrowPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.pointLeft != pointLeft;
  }
}
