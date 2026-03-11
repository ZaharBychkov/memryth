import 'package:flutter/material.dart';

import '../models/quote.dart';
import '../repositories/quote_repository.dart';
import '../repositories/tag_repository.dart';
import '../settings/app_settings_scope.dart';
import '../settings/app_strings.dart';
import '../viewmodels/quote_edit_view_model.dart';

class QuoteEditScreen extends StatefulWidget {
  const QuoteEditScreen({
    super.key,
    required this.quoteRepository,
    required this.tagRepository,
    this.quote,
  });

  final QuoteRepository quoteRepository;
  final TagRepository tagRepository;
  final Quote? quote;

  @override
  State<QuoteEditScreen> createState() => _QuoteEditScreenState();
}

class _QuoteEditScreenState extends State<QuoteEditScreen> {
  late final QuoteEditViewModel _viewModel = QuoteEditViewModel(
    quoteRepository: widget.quoteRepository,
    tagRepository: widget.tagRepository,
    quote: widget.quote,
  );

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings(AppSettingsScope.of(context).settings.language);

    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final fillColor = isDark ? const Color(0xFF262B33) : Colors.white;
        final border = OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1.5,
          ),
        );

        return PopScope(
          canPop: !_viewModel.hasUnsavedChanges,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            final canLeave = await _handleBackNavigation(strings);
            if (!mounted || !canLeave) return;
            Navigator.of(this.context).pop();
          },
          child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () async {
                  final canLeave = await _handleBackNavigation(strings);
                  if (!mounted || !canLeave) return;
                  Navigator.of(this.context).pop();
                },
              ),
              title: Text(
                _viewModel.isEditing ? strings.editTitle : strings.createTitle,
              ),
              actions: [
                FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF4A6FA5),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(_viewModel.isEditing ? strings.save : strings.add),
                ),
                const SizedBox(width: 12),
              ],
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.typeEntry,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final type in QuoteType.values)
                          ChoiceChip(
                            label: Text(strings.quoteTypeLabel(type)),
                            selected: _viewModel.selectedType == type,
                            onSelected: (_) => _viewModel.setSelectedType(type),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(strings.createdAt),
                      subtitle: Text(_formatDate(_viewModel.createdAt)),
                      trailing: TextButton(
                        onPressed: _pickCreatedAt,
                        child: Text(strings.changeDate),
                      ),
                    ),
                    const SizedBox(height: 4),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(strings.addToFavorites),
                      subtitle: Text(
                        strings.favoriteHint,
                        style: const TextStyle(fontSize: 13),
                      ),
                      value: _viewModel.isFavorite,
                      activeThumbColor: const Color(0xFFE4A11B),
                      onChanged: _viewModel.setFavorite,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _viewModel.textController,
                      minLines: 6,
                      maxLines: null,
                      textInputAction: TextInputAction.newline,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                      decoration: _inputDecoration(
                        context: context,
                        border: border,
                        fillColor: fillColor,
                        labelText: _viewModel.selectedType == QuoteType.thought
                            ? strings.entryTextThought
                            : strings.entryText,
                        hintText: _viewModel.selectedType == QuoteType.excerpt
                            ? strings.hintExcerpt
                            : strings.hintEntry,
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _viewModel.authorController,
                      decoration: _inputDecoration(
                        context: context,
                        border: border,
                        fillColor: fillColor,
                        labelText: _viewModel.selectedType == QuoteType.thought
                            ? strings.authorOptional
                            : strings.author,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _viewModel.sourceTitleController,
                      decoration: _inputDecoration(
                        context: context,
                        border: border,
                        fillColor: fillColor,
                        labelText: strings.source,
                        hintText: strings.sourceHint,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _viewModel.sourceDetailsController,
                      decoration: _inputDecoration(
                        context: context,
                        border: border,
                        fillColor: fillColor,
                        labelText: strings.sourceDetails,
                        hintText: strings.sourceDetailsHint,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _viewModel.noteController,
                      minLines: 3,
                      maxLines: null,
                      textInputAction: TextInputAction.newline,
                      decoration: _inputDecoration(
                        context: context,
                        border: border,
                        fillColor: fillColor,
                        labelText: strings.note,
                        hintText: strings.noteHint,
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(strings.tags, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (var index = 0; index < _viewModel.draftTags.length; index++)
                          InputChip(
                            label: Text(_viewModel.draftTags[index].name),
                            side: BorderSide(
                              color: Theme.of(context).dividerColor,
                              width: 1.2,
                            ),
                            backgroundColor: isDark
                                ? const Color(0xFF262B33)
                                : const Color(0xFFF5EEE7),
                            onDeleted: () => _viewModel.removeTagAt(index),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _viewModel.tagController,
                            onSubmitted: (_) => _viewModel.addTagFromInput(),
                            decoration: _inputDecoration(
                              context: context,
                              border: border,
                              fillColor: fillColor,
                              labelText: strings.newTag,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 56,
                          child: FilledButton(
                            onPressed: _viewModel.addTagFromInput,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF4A6FA5),
                              foregroundColor: Colors.white,
                            ),
                            child: Text(strings.add),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  InputDecoration _inputDecoration({
    required BuildContext context,
    required OutlineInputBorder border,
    required Color fillColor,
    required String labelText,
    String? hintText,
    bool alignLabelWithHint = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      labelStyle: TextStyle(
        color: isDark ? const Color(0xFFB8AEA2) : const Color(0xFF8B7E74),
      ),
      hintStyle: TextStyle(
        color: isDark ? const Color(0xFF8F867A) : const Color(0xFF8B7E74),
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
      alignLabelWithHint: alignLabelWithHint,
    );
  }

  Future<bool> _handleBackNavigation(AppStrings strings) async {
    if (!_viewModel.hasUnsavedChanges) return true;

    final approved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(strings.exitWithoutSaving),
          content: Text(strings.changesLost),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(strings.stay),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB84A3A),
                foregroundColor: Colors.white,
              ),
              child: Text(strings.exit),
            ),
          ],
        );
      },
    );

    return approved == true;
  }

  Future<void> _save() async {
    final saved = await _viewModel.save();
    if (saved && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _pickCreatedAt() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _viewModel.createdAt,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    _viewModel.setCreatedAt(picked);
  }

  String _formatDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}';
  }
}
