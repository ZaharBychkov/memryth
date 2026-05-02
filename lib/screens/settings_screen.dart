import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../repositories/quote_repository.dart';
import '../repositories/tag_repository.dart';
import '../services/export_import_service.dart';
import '../services/pin_lock_service.dart';
import '../settings/app_settings.dart';
import '../settings/app_settings_controller.dart';
import '../settings/app_strings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.controller});

  final AppSettingsController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final text = _SettingsText(controller.settings.language);

        return Scaffold(
          appBar: AppBar(title: Text(text.settings)),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _SettingsTile(
                  icon: Icons.text_fields_rounded,
                  title: text.reading,
                  subtitle: text.readingSubtitle,
                  onTap: () => _push(
                    context,
                    ReadingSettingsScreen(controller: controller),
                  ),
                ),
                _SettingsTile(
                  icon: Icons.archive_rounded,
                  title: text.data,
                  subtitle: text.dataSubtitle,
                  onTap: () => _push(
                    context,
                    DataSettingsScreen(controller: controller),
                  ),
                ),
                _SettingsTile(
                  icon: Icons.privacy_tip_rounded,
                  title: text.privacy,
                  subtitle: text.privacySubtitle,
                  onTap: () => _push(
                    context,
                    PrivacySettingsScreen(controller: controller),
                  ),
                ),
                _SettingsTile(
                  icon: Icons.person_rounded,
                  title: text.account,
                  subtitle: text.accountSubtitle,
                  onTap: () => _push(
                    context,
                    AccountSettingsScreen(controller: controller),
                  ),
                ),
                _SettingsTile(
                  icon: Icons.info_rounded,
                  title: text.about,
                  subtitle: text.aboutSubtitle,
                  onTap: () => _push(
                    context,
                    AboutSettingsScreen(controller: controller),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }
}

class ReadingSettingsScreen extends StatelessWidget {
  const ReadingSettingsScreen({super.key, required this.controller});

  final AppSettingsController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final settings = controller.settings;
        final strings = AppStrings(settings.language);
        final text = _SettingsText(settings.language);

        return Scaffold(
          appBar: AppBar(title: Text(text.reading)),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _PreviewCard(settings: settings),
                const SizedBox(height: 16),
                _SectionTitle(text.appearance),
                _SegmentedOptions<AppThemeMode>(
                  values: AppThemeMode.values,
                  currentValue: settings.themeMode,
                  labelBuilder: (value) => value.label(settings.language),
                  onSelected: controller.setThemeMode,
                ),
                const SizedBox(height: 16),
                _SectionTitle(strings.languageTitle),
                _SegmentedOptions<AppLanguage>(
                  values: AppLanguage.values,
                  currentValue: settings.language,
                  labelBuilder: (value) =>
                      value == AppLanguage.ru ? 'RU' : 'EN',
                  onSelected: controller.setLanguage,
                ),
                const SizedBox(height: 20),
                _SectionTitle(text.readingText),
                _DoubleSlider(
                  title: strings.quoteTextTitle,
                  value: settings.quoteTextSize,
                  min: 18,
                  max: 28,
                  valueLabel: (value) => value.toStringAsFixed(1),
                  onChanged: controller.setQuoteTextSize,
                ),
                _DoubleSlider(
                  title: strings.lineSpacingTitle,
                  value: settings.quoteLineSpacing,
                  min: 1.25,
                  max: 1.65,
                  valueLabel: (value) => value.toStringAsFixed(2),
                  onChanged: controller.setQuoteLineSpacing,
                ),
                const SizedBox(height: 20),
                _SectionTitle(text.cards),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(strings.showNote),
                  value: settings.showNotePreview,
                  onChanged: controller.setShowNotePreview,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(strings.showMeta),
                  value: settings.showMetaPreview,
                  onChanged: controller.setShowMetaPreview,
                ),
                const SizedBox(height: 20),
                _SectionTitle(text.reset),
                OutlinedButton.icon(
                  onPressed: () => _confirmReset(context, text),
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: Text(text.resetSettings),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmReset(BuildContext context, _SettingsText text) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(text.resetSettings),
          content: Text(text.resetWarning),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(text.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(text.reset),
            ),
          ],
        );
      },
    );

    if (approved == true) {
      await controller.resetSettings();
    }
  }
}

class DataSettingsScreen extends StatefulWidget {
  const DataSettingsScreen({super.key, required this.controller});

  final AppSettingsController controller;

  @override
  State<DataSettingsScreen> createState() => _DataSettingsScreenState();
}

class _DataSettingsScreenState extends State<DataSettingsScreen> {
  bool _isBusy = false;

  ExportImportService get _service {
    return ExportImportService(
      quoteRepository: HiveQuoteRepository(),
      tagRepository: HiveTagRepository(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = _SettingsText(widget.controller.settings.language);

    return Scaffold(
      appBar: AppBar(title: Text(text.data)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _InfoPanel(
              icon: Icons.storage_rounded,
              title: text.localData,
              body: text.localDataBody,
            ),
            const SizedBox(height: 16),
            _ActionRow(
              icon: Icons.file_upload_rounded,
              title: text.exportLibrary,
              subtitle: _isBusy ? text.processing : text.exportSubtitle,
              onTap: _isBusy ? null : () => _exportLibrary(text),
            ),
            _ActionRow(
              icon: Icons.file_download_rounded,
              title: text.importLibrary,
              subtitle: _isBusy ? text.processing : text.importSubtitle,
              onTap: _isBusy ? null : () => _importLibrary(text),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportLibrary(_SettingsText text) async {
    await _guard(text, () async {
      final file = await _service.writeExportFile();
      if (!mounted) {
        return;
      }
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/json')],
          subject: text.exportShareSubject,
          text: text.exportShareText,
          fileNameOverrides: [file.uri.pathSegments.last],
        ),
      );
      if (!mounted) {
        return;
      }
      _showSnack(text.exportReady);
    });
  }

  Future<void> _importLibrary(_SettingsText text) async {
    await _guard(text, () async {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
        allowMultiple: false,
        withData: false,
      );

      final path = result?.files.single.path;
      if (path == null) {
        return;
      }

      final source = await File(path).readAsString();
      final preview = _service.previewImportJson(source);
      if (!mounted) {
        return;
      }

      final approved = await _confirmImport(text, preview);
      if (approved != true || !mounted) {
        return;
      }

      final importResult = await _service.importJsonMerge(source);
      if (!mounted) {
        return;
      }
      _showSnack(text.importCompleted(importResult));
    });
  }

  Future<void> _guard(
    _SettingsText text,
    Future<void> Function() action,
  ) async {
    if (_isBusy) {
      return;
    }

    setState(() => _isBusy = true);
    try {
      await action();
    } on ImportFormatException catch (error) {
      if (mounted) {
        _showSnack(text.importFailed(error.message));
      }
    } on Object catch (error) {
      if (mounted) {
        _showSnack(text.operationFailed(error));
      }
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<bool?> _confirmImport(
    _SettingsText text,
    ImportPreview preview,
  ) async {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(text.confirmImportTitle),
          content: Text(text.confirmImportBody(preview)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(text.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(text.importMerge),
            ),
          ],
        );
      },
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({super.key, required this.controller});

  final AppSettingsController controller;

  @override
  Widget build(BuildContext context) {
    final text = _SettingsText(controller.settings.language);

    return Scaffold(
      appBar: AppBar(title: Text(text.privacy)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _InfoPanel(
              icon: Icons.lock_rounded,
              title: text.offlineFirst,
              body: text.offlineFirstBody,
            ),
            const SizedBox(height: 16),
            _ActionRow(
              icon: Icons.policy_rounded,
              title: text.privacyPolicy,
              subtitle: text.privacyPolicySubtitle,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PrivacyPolicyScreen(controller: controller),
                ),
              ),
            ),
            _ActionRow(
              icon: Icons.backup_rounded,
              title: text.localBackup,
              subtitle: text.localBackupSubtitle,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => DataSettingsScreen(controller: controller),
                ),
              ),
            ),
            _ActionRow(
              icon: Icons.fingerprint_rounded,
              title: text.appLock,
              subtitle: text.appLockSubtitle,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => AppLockSettingsScreen(controller: controller),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppLockSettingsScreen extends StatelessWidget {
  const AppLockSettingsScreen({super.key, required this.controller});

  final AppSettingsController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final text = _SettingsText(controller.settings.language);
        final enabled = controller.settings.appLockEnabled;

        return Scaffold(
          appBar: AppBar(title: Text(text.appLock)),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _InfoPanel(
                  icon: Icons.pin_rounded,
                  title: enabled ? text.pinLockOn : text.pinLockOff,
                  body: text.pinLockBody,
                ),
                const SizedBox(height: 16),
                _ActionRow(
                  icon: Icons.password_rounded,
                  title: enabled ? text.changePin : text.enablePinLock,
                  subtitle: enabled
                      ? text.changePinSubtitle
                      : text.enablePinLockSubtitle,
                  onTap: () => _setPin(context, text),
                ),
                if (enabled)
                  _ActionRow(
                    icon: Icons.lock_open_rounded,
                    title: text.disablePinLock,
                    subtitle: text.disablePinLockSubtitle,
                    onTap: () => _disablePin(context, text),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _setPin(BuildContext context, _SettingsText text) async {
    final pin = await showDialog<String>(
      context: context,
      builder: (context) => _PinSetupDialog(text: text),
    );
    if (pin == null) {
      return;
    }

    await controller.setPinLock(pin);
    if (!context.mounted) {
      return;
    }
    _showSnack(context, text.pinLockSaved);
  }

  Future<void> _disablePin(BuildContext context, _SettingsText text) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(text.disablePinLock),
          content: Text(text.disablePinWarning),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(text.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(text.disable),
            ),
          ],
        );
      },
    );

    if (approved != true) {
      return;
    }
    await controller.disablePinLock();
    if (!context.mounted) {
      return;
    }
    _showSnack(context, text.pinLockDisabled);
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _PinSetupDialog extends StatefulWidget {
  const _PinSetupDialog({required this.text});

  final _SettingsText text;

  @override
  State<_PinSetupDialog> createState() => _PinSetupDialogState();
}

class _PinSetupDialogState extends State<_PinSetupDialog> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _repeatController = TextEditingController();
  String _error = '';

  @override
  void dispose() {
    _pinController.dispose();
    _repeatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.text;

    return AlertDialog(
      title: Text(text.setPinTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text.setPinBody),
          const SizedBox(height: 14),
          _pinField(
            controller: _pinController,
            label: text.pin,
            autofocus: true,
          ),
          const SizedBox(height: 10),
          _pinField(
            controller: _repeatController,
            label: text.repeatPin,
            onSubmitted: (_) => _submit(),
          ),
          if (_error.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              _error,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(text.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(text.save)),
      ],
    );
  }

  Widget _pinField({
    required TextEditingController controller,
    required String label,
    bool autofocus = false,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      obscureText: true,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(PinLockService.maxPinLength),
      ],
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  void _submit() {
    final pin = _pinController.text;
    final repeat = _repeatController.text;
    final text = widget.text;

    if (!PinLockService.isValidPin(pin)) {
      setState(() => _error = text.pinFormatError);
      return;
    }

    if (pin != repeat) {
      setState(() => _error = text.pinMismatch);
      return;
    }

    Navigator.of(context).pop(pin);
  }
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key, required this.controller});

  final AppSettingsController controller;

  @override
  Widget build(BuildContext context) {
    final text = _SettingsText(controller.settings.language);

    return Scaffold(
      appBar: AppBar(title: Text(text.privacyPolicy)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _InfoPanel(
              icon: Icons.lock_rounded,
              title: text.privacyPolicyIntroTitle,
              body: text.privacyPolicyIntroBody,
            ),
            const SizedBox(height: 16),
            _PolicySection(
              title: text.dataStoredTitle,
              body: text.dataStoredBody,
            ),
            _PolicySection(
              title: text.localStorageTitle,
              body: text.localStorageBody,
            ),
            _PolicySection(
              title: text.exportImportTitle,
              body: text.exportImportBody,
            ),
            _PolicySection(
              title: text.noNetworkTitle,
              body: text.noNetworkBody,
            ),
            _PolicySection(
              title: text.dataDeletionTitle,
              body: text.dataDeletionBody,
            ),
          ],
        ),
      ),
    );
  }
}

class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key, required this.controller});

  final AppSettingsController controller;

  @override
  Widget build(BuildContext context) {
    final text = _SettingsText(controller.settings.language);

    return Scaffold(
      appBar: AppBar(title: Text(text.account)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _InfoPanel(
              icon: Icons.person_outline_rounded,
              title: text.noAccountRequired,
              body: text.noAccountRequiredBody,
            ),
            const SizedBox(height: 16),
            _ActionRow(
              icon: Icons.cloud_sync_rounded,
              title: text.syncAccount,
              subtitle: text.syncAccountSubtitle,
              onTap: () => _showNextStep(context, text),
            ),
          ],
        ),
      ),
    );
  }
}

class AboutSettingsScreen extends StatelessWidget {
  const AboutSettingsScreen({super.key, required this.controller});

  final AppSettingsController controller;

  @override
  Widget build(BuildContext context) {
    final text = _SettingsText(controller.settings.language);

    return Scaffold(
      appBar: AppBar(title: Text(text.about)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _InfoPanel(
              icon: Icons.auto_stories_rounded,
              title: 'MEMRYTH',
              body: text.aboutBody,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                _IconShell(icon: icon),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Theme.of(context).hintColor,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = _SettingsText(settings.language);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text.previewTitle,
            style: TextStyle(
              color: isDark ? const Color(0xFFB8AEA2) : const Color(0xFF8B7E74),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            text.previewBody,
            style: TextStyle(
              fontSize: settings.quoteTextSize,
              height: settings.quoteLineSpacing,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DoubleSlider extends StatelessWidget {
  const _DoubleSlider({
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.valueLabel,
    required this.onChanged,
  });

  final String title;
  final double value;
  final double min;
  final double max;
  final String Function(double value) valueLabel;
  final Future<void> Function(double value) onChanged;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(min, max);

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                valueLabel(clamped),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          Slider(
            min: min,
            max: max,
            value: clamped,
            label: valueLabel(clamped),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SegmentedOptions<T> extends StatelessWidget {
  const _SegmentedOptions({
    required this.values,
    required this.currentValue,
    required this.labelBuilder,
    required this.onSelected,
    this.columns = 3,
  });

  final List<T> values;
  final T currentValue;
  final String Function(T value) labelBuilder;
  final Future<void> Function(T value) onSelected;
  final int columns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - ((columns - 1) * 8)) / columns;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final value in values)
              SizedBox(
                width: width,
                child: _OptionButton(
                  label: labelBuilder(value),
                  selected: value == currentValue,
                  onTap: () => onSelected(value),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({
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
        height: 42,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8),
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
        child: FittedBox(
          fit: BoxFit.scaleDown,
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
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 6),
      leading: _IconShell(icon: icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconShell(icon: icon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(body, style: const TextStyle(height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IconShell extends StatelessWidget {
  const _IconShell({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262B33) : const Color(0xFFF5EEE7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: Theme.of(context).colorScheme.primary),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).hintColor,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(body, style: const TextStyle(height: 1.42)),
        ],
      ),
    );
  }
}

void _showNextStep(BuildContext context, _SettingsText text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text.nextStep)));
}

class _SettingsText {
  const _SettingsText(this.language);

  final AppLanguage language;

  bool get isRu => language == AppLanguage.ru;

  String get settings => isRu ? 'Настройки' : 'Settings';
  String get reading =>
      isRu ? 'Чтение и внешний вид' : 'Reading and appearance';
  String get readingSubtitle => isRu
      ? 'Тема, язык, размер текста и интервал'
      : 'Theme, language, text size and spacing';
  String get data => isRu ? 'Данные и резервная копия' : 'Data and backup';
  String get dataSubtitle => isRu
      ? 'Экспорт, импорт и восстановление библиотеки'
      : 'Export, import and restore your library';
  String get privacy =>
      isRu ? 'Приватность и безопасность' : 'Privacy and security';
  String get privacySubtitle => isRu
      ? 'Локальное хранение, защита и политика'
      : 'Local storage, protection and policy';
  String get account => isRu ? 'Аккаунт' : 'Account';
  String get accountSubtitle => isRu
      ? 'Опциональная синхронизация в будущем'
      : 'Optional sync in the future';
  String get about => isRu ? 'О приложении' : 'About';
  String get aboutSubtitle => isRu
      ? 'Версия, идея продукта и справка'
      : 'Version, product idea and help';
  String get appearance => isRu ? 'Внешний вид' : 'Appearance';
  String get readingText => isRu ? 'Текст записи' : 'Entry text';
  String get cards => isRu ? 'Карточки' : 'Cards';
  String get reset => isRu ? 'Сброс' : 'Reset';
  String get resetSettings =>
      isRu ? 'Сбросить настройки интерфейса' : 'Reset interface settings';
  String get resetWarning => isRu
      ? 'Записи, темы и заметки не будут удалены. Сбросятся только настройки внешнего вида и чтения.'
      : 'Entries, topics and notes will not be deleted. Only appearance and reading settings will be reset.';
  String get cancel => isRu ? 'Отмена' : 'Cancel';
  String get save => isRu ? 'Сохранить' : 'Save';
  String get disable => isRu ? 'Отключить' : 'Disable';
  String get previewTitle => isRu ? 'Предпросмотр' : 'Preview';
  String get previewBody => isRu
      ? 'Сохраненный фрагмент должен читаться спокойно и без лишнего шума.'
      : 'A saved excerpt should read calmly without visual noise.';
  String get localData => isRu ? 'Локальная библиотека' : 'Local library';
  String get localDataBody => isRu
      ? 'Записи хранятся на устройстве. Экспортируйте JSON-файл, чтобы сохранить резервную копию или перенести библиотеку.'
      : 'Entries are stored on this device. Export a JSON file to keep a backup or move your library.';
  String get exportLibrary =>
      isRu ? 'Экспортировать библиотеку' : 'Export library';
  String get exportSubtitle => isRu
      ? 'Сохранить все записи и темы в JSON'
      : 'Save all entries and topics to JSON';
  String get importLibrary =>
      isRu ? 'Импортировать из файла' : 'Import from file';
  String get importSubtitle => isRu
      ? 'Объединить библиотеку с backup-файлом'
      : 'Merge the library with a backup file';
  String get processing => isRu ? 'Выполняется...' : 'Working...';
  String get exportShareSubject => isRu ? 'Backup MEMRYTH' : 'MEMRYTH backup';
  String get exportShareText =>
      isRu ? 'Резервная копия библиотеки MEMRYTH' : 'MEMRYTH library backup';
  String get exportReady =>
      isRu ? 'Файл экспорта подготовлен' : 'Export file is ready';
  String get confirmImportTitle =>
      isRu ? 'Импортировать backup?' : 'Import backup?';
  String confirmImportBody(ImportPreview preview) {
    final date = _formatDateTime(preview.exportedAt);
    return isRu
        ? 'Файл от $date содержит тем: ${preview.tagCount}, записей: ${preview.quoteCount}.\n\nИмпорт объединит данные с текущей библиотекой. Существующие записи не будут перезаписаны.'
        : 'The file from $date contains ${preview.tagCount} topics and ${preview.quoteCount} entries.\n\nImport will merge data with the current library. Existing entries will not be overwritten.';
  }

  String get importMerge => isRu ? 'Объединить' : 'Merge';
  String importCompleted(ImportResult result) {
    return isRu
        ? 'Импорт завершен: записей добавлено ${result.addedQuotes}, тем добавлено ${result.addedTags}, тем переиспользовано ${result.reusedTags}.'
        : 'Import complete: ${result.addedQuotes} entries added, ${result.addedTags} topics added, ${result.reusedTags} topics reused.';
  }

  String importFailed(String message) {
    return isRu ? 'Импорт не выполнен: $message' : 'Import failed: $message';
  }

  String operationFailed(Object error) {
    return isRu ? 'Операция не выполнена: $error' : 'Operation failed: $error';
  }

  String get offlineFirst => isRu ? 'Offline-first' : 'Offline-first';
  String get offlineFirstBody => isRu
      ? 'MEMRYTH работает без обязательного аккаунта. Библиотека хранится локально на устройстве.'
      : 'MEMRYTH works without a required account. Your library is stored locally on this device.';
  String get privacyPolicy =>
      isRu ? 'Политика конфиденциальности' : 'Privacy policy';
  String get privacyPolicySubtitle => isRu
      ? 'Что хранится локально и что не отправляется'
      : 'What is stored locally and what is not sent';
  String get localBackup => isRu ? 'Локальный backup' : 'Local backup';
  String get localBackupSubtitle => isRu
      ? 'Экспорт и импорт резервной копии'
      : 'Export and import backup files';
  String get appLock => isRu ? 'PIN / биометрия' : 'PIN / biometrics';
  String get appLockSubtitle => isRu
      ? 'PIN-защита входа, биометрия позже'
      : 'PIN app lock, biometrics later';
  String get pinLockOn => isRu ? 'PIN-защита включена' : 'PIN lock is on';
  String get pinLockOff => isRu ? 'PIN-защита выключена' : 'PIN lock is off';
  String get pinLockBody => isRu
      ? 'PIN блокирует вход в приложение после запуска. Это не шифрование базы данных, но снижает риск случайного доступа к личной библиотеке.'
      : 'PIN locks the app after launch. This is not database encryption, but it reduces casual access to your private library.';
  String get enablePinLock => isRu ? 'Включить PIN-защиту' : 'Enable PIN lock';
  String get enablePinLockSubtitle =>
      isRu ? 'Создать PIN из 4-8 цифр' : 'Create a 4-8 digit PIN';
  String get changePin => isRu ? 'Изменить PIN' : 'Change PIN';
  String get changePinSubtitle => isRu
      ? 'Заменить текущий PIN новым'
      : 'Replace the current PIN with a new one';
  String get disablePinLock =>
      isRu ? 'Отключить PIN-защиту' : 'Disable PIN lock';
  String get disablePinLockSubtitle =>
      isRu ? 'Открывать приложение без PIN' : 'Open the app without a PIN';
  String get disablePinWarning => isRu
      ? 'Приложение перестанет запрашивать PIN при запуске. Записи и backup-файлы не будут удалены.'
      : 'The app will stop asking for a PIN on launch. Entries and backup files will not be deleted.';
  String get setPinTitle => isRu ? 'Настроить PIN' : 'Set PIN';
  String get setPinBody => isRu
      ? 'Введите PIN из 4-8 цифр и повторите его.'
      : 'Enter a 4-8 digit PIN and repeat it.';
  String get pin => isRu ? 'PIN' : 'PIN';
  String get repeatPin => isRu ? 'Повторите PIN' : 'Repeat PIN';
  String get pinFormatError => isRu
      ? 'PIN должен содержать от 4 до 8 цифр.'
      : 'PIN must contain 4 to 8 digits.';
  String get pinMismatch => isRu ? 'PIN не совпадает.' : 'PIN does not match.';
  String get pinLockSaved => isRu ? 'PIN-защита включена' : 'PIN lock enabled';
  String get pinLockDisabled =>
      isRu ? 'PIN-защита отключена' : 'PIN lock disabled';
  String get privacyPolicyIntroTitle =>
      isRu ? 'Локально и без аккаунта' : 'Local and account-free';
  String get privacyPolicyIntroBody => isRu
      ? 'MEMRYTH предназначен для личной офлайн-библиотеки. В текущей версии нет облачной синхронизации, аналитики, рекламы или AI-обработки.'
      : 'MEMRYTH is built as a private offline library. The current version has no cloud sync, analytics, ads, or AI processing.';
  String get dataStoredTitle => isRu ? 'Какие данные хранятся' : 'Data stored';
  String get dataStoredBody => isRu
      ? 'На устройстве сохраняются записи, темы, авторы, источники, заметки, избранное, даты записей, настройки чтения и факт завершения первого запуска.'
      : 'The app stores entries, topics, authors, sources, notes, favorites, entry dates, reading settings, and onboarding completion on your device.';
  String get localStorageTitle => isRu ? 'Локальное хранение' : 'Local storage';
  String get localStorageBody => isRu
      ? 'Библиотека хранится в локальном хранилище приложения. MEMRYTH не требует аккаунта и не управляет сервером с вашими записями.'
      : 'Your library is kept in local app storage. MEMRYTH does not require an account and does not operate a server for your entries.';
  String get exportImportTitle =>
      isRu ? 'Экспорт и импорт' : 'Export and import';
  String get exportImportBody => isRu
      ? 'Вы можете экспортировать библиотеку в JSON-файл и импортировать backup обратно. После сохранения или отправки файла через системный Android sheet контроль над этим файлом находится у вас.'
      : 'You can export your library to a JSON file and import a backup back into the app. After saving or sharing the file through the Android system sheet, you control that file.';
  String get noNetworkTitle =>
      isRu ? 'Сеть и третьи стороны' : 'Network and third parties';
  String get noNetworkBody => isRu
      ? 'В текущем релизе нет облачного backup, синхронизации, рекламы, аналитики или передачи библиотеки разработчику.'
      : 'The current release has no cloud backup, sync, ads, analytics, or library transfer to the developer.';
  String get dataDeletionTitle => isRu ? 'Удаление данных' : 'Data deletion';
  String get dataDeletionBody => isRu
      ? 'Отдельные записи можно удалить в приложении. Удаление приложения удаляет локальные данные по правилам Android, кроме backup-файлов, которые вы экспортировали самостоятельно.'
      : 'You can delete individual entries in the app. Uninstalling the app removes local app data according to Android behavior, except backup files you exported yourself.';
  String get noAccountRequired =>
      isRu ? 'Аккаунт не обязателен' : 'No account required';
  String get noAccountRequiredBody => isRu
      ? 'Базовое приложение остается локальным. Аккаунт нужен только для будущей синхронизации и облачного backup.'
      : 'The core app stays local. An account is only for future sync and cloud backup.';
  String get syncAccount => isRu ? 'Синхронизация' : 'Sync';
  String get syncAccountSubtitle => isRu
      ? 'Будущий слой для нескольких устройств'
      : 'Future layer for multiple devices';
  String get aboutBody => isRu
      ? 'Личная офлайн-библиотека мыслей, цитат и фрагментов.'
      : 'A private offline library for thoughts, quotes and excerpts.';
  String get nextStep => isRu
      ? 'Этот раздел будет реализован следующим блоком.'
      : 'This section will be implemented next.';

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}
