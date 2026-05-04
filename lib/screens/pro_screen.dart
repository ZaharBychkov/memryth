import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../services/pro_purchase_service.dart';
import '../settings/app_settings.dart';
import '../settings/app_settings_controller.dart';

class ProScreen extends StatefulWidget {
  const ProScreen({
    super.key,
    required this.controller,
    ProPurchaseService? purchaseService,
  }) : _purchaseService = purchaseService;

  final AppSettingsController controller;
  final ProPurchaseService? _purchaseService;

  @override
  State<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends State<ProScreen> {
  late final ProPurchaseService _purchaseService;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  ProProductStatus? _productStatus;
  bool _loading = true;
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _purchaseService = widget._purchaseService ?? ProPurchaseService();
    _purchaseSubscription = _purchaseService.purchaseStream.listen(
      _handlePurchases,
      onError: (Object error) {
        if (mounted) {
          setState(() {
            _busy = false;
            _message = _text.purchaseFailed(error);
          });
        }
      },
    );
    unawaited(_loadProduct());
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }

  _ProText get _text => _ProText(widget.controller.settings.language);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final text = _text;
        final settings = widget.controller.settings;

        return Scaffold(
          appBar: AppBar(title: Text(text.title)),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
              children: [
                _HeroPanel(text: text, settings: settings),
                const SizedBox(height: 18),
                for (final feature in text.features)
                  _FeatureRow(feature: feature),
                const SizedBox(height: 20),
                _buildPrimaryAction(text, settings),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _busy || _loading || settings.proUnlocked
                      ? null
                      : _restorePurchases,
                  icon: const Icon(Icons.restore_rounded),
                  label: Text(text.restorePurchases),
                ),
                if (_message != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _message!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).hintColor,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  text.billingNote(_productStatus),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).hintColor,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrimaryAction(_ProText text, AppSettings settings) {
    if (settings.proUnlocked) {
      return FilledButton.icon(
        onPressed: null,
        icon: const Icon(Icons.verified_rounded),
        label: Text(text.proActive),
      );
    }

    final status = _productStatus;
    final product = status?.product;
    final label = _primaryActionLabel(text, status, product);

    return FilledButton.icon(
      onPressed: status?.canPurchase == true && !_busy
          ? () => _buyProduct(product!)
          : null,
      icon: _loading || _busy
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.lock_open_rounded),
      label: Text(label),
    );
  }

  String _primaryActionLabel(
    _ProText text,
    ProProductStatus? status,
    ProductDetails? product,
  ) {
    if (_loading) {
      return text.checkingGooglePlay;
    }
    if (_busy) {
      return text.processingPurchase;
    }
    if (status == null) {
      return text.checkingGooglePlay;
    }
    if (!status.productConfigured) {
      return text.productNotConfigured;
    }
    if (!status.storeAvailable) {
      return text.googlePlayUnavailable;
    }
    if (product == null) {
      return text.productMissing;
    }
    return text.unlockFor(product.price);
  }

  Future<void> _loadProduct() async {
    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      final status = await _purchaseService.loadProduct();
      if (!mounted) {
        return;
      }
      setState(() {
        _productStatus = status;
        _loading = false;
        _message = status.errorMessage;
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _message = _text.purchaseFailed(error);
      });
    }
  }

  Future<void> _buyProduct(ProductDetails product) async {
    setState(() {
      _busy = true;
      _message = null;
    });

    try {
      final started = await _purchaseService.buyPro(product);
      if (!mounted) {
        return;
      }
      if (!started) {
        setState(() {
          _busy = false;
          _message = _text.purchaseCouldNotStart;
        });
      }
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _message = _text.purchaseFailed(error);
      });
    }
  }

  Future<void> _restorePurchases() async {
    setState(() {
      _busy = true;
      _message = null;
    });

    try {
      await _purchaseService.restorePurchases();
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _message = _text.restoreStarted;
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _message = _text.purchaseFailed(error);
      });
    }
  }

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID != _purchaseService.productId) {
        continue;
      }

      if (purchase.status == PurchaseStatus.pending) {
        if (mounted) {
          setState(() {
            _busy = true;
            _message = _text.purchasePending;
          });
        }
        continue;
      }

      if (purchase.status == PurchaseStatus.error) {
        if (mounted) {
          setState(() {
            _busy = false;
            _message =
                purchase.error?.message ?? _text.purchaseCouldNotComplete;
          });
        }
      }

      if (_purchaseService.isCompletedProPurchase(purchase)) {
        await widget.controller.markProUnlocked(DateTime.now());
        if (mounted) {
          setState(() {
            _busy = false;
            _message = _text.proUnlocked;
          });
        }
      }

      if (purchase.pendingCompletePurchase) {
        await _purchaseService.completePurchase(purchase);
      }
    }
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.text, required this.settings});

  final _ProText text;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withAlpha(30),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              settings.proUnlocked
                  ? Icons.verified_rounded
                  : Icons.workspace_premium_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            settings.proUnlocked ? text.activeHeroTitle : text.heroTitle,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            settings.proUnlocked ? text.activeHeroBody : text.heroBody,
            style: const TextStyle(height: 1.42),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.feature});

  final _ProFeature feature;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withAlpha(22),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              feature.icon,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  feature.body,
                  style: TextStyle(
                    color: Theme.of(context).hintColor,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProText {
  const _ProText(this.language);

  final AppLanguage language;

  bool get isRu => language == AppLanguage.ru;

  String get title => 'MEMRYTH Pro';
  String get heroTitle =>
      isRu ? 'Pro без подписки' : 'Pro without subscription';
  String get heroBody => isRu
      ? 'Бесплатное ядро и разовая покупка Pro для расширенных локальных функций.'
      : 'Free core features and a one-time Pro unlock for advanced local tools.';
  String get activeHeroTitle => isRu ? 'Pro включен' : 'Pro is active';
  String get activeHeroBody => isRu
      ? 'Расширенные функции будут открываться здесь по мере добавления новых Pro-инструментов.'
      : 'Advanced features will unlock here as new Pro tools are added.';
  String get checkingGooglePlay =>
      isRu ? 'Проверка Google Play...' : 'Checking Google Play...';
  String get processingPurchase =>
      isRu ? 'Обработка покупки...' : 'Processing purchase...';
  String get productNotConfigured =>
      isRu ? 'Product id не настроен' : 'Product id is not configured';
  String get googlePlayUnavailable =>
      isRu ? 'Google Play недоступен' : 'Google Play unavailable';
  String get productMissing =>
      isRu ? 'Товар Pro пока недоступен' : 'Pro product unavailable';
  String unlockFor(String price) =>
      isRu ? 'Открыть Pro за $price' : 'Unlock Pro for $price';
  String get proActive => isRu ? 'Pro уже включен' : 'Pro already active';
  String get restorePurchases =>
      isRu ? 'Восстановить покупку' : 'Restore purchase';
  String get restoreStarted =>
      isRu ? 'Проверка покупок запущена' : 'Purchase restore started';
  String get purchasePending =>
      isRu ? 'Покупка ожидает подтверждения' : 'Purchase is pending';
  String get purchaseCouldNotStart =>
      isRu ? 'Не удалось начать покупку' : 'Could not start purchase';
  String get purchaseCouldNotComplete =>
      isRu ? 'Не удалось завершить покупку' : 'Could not complete purchase';
  String get proUnlocked =>
      isRu ? 'MEMRYTH Pro включен' : 'MEMRYTH Pro unlocked';
  String purchaseFailed(Object error) {
    return isRu ? 'Покупка недоступна: $error' : 'Purchase unavailable: $error';
  }

  String billingNote(ProProductStatus? status) {
    final productId = status?.productId ?? ProPurchaseService.defaultProductId;
    if (status?.canPurchase == true) {
      return isRu
          ? 'Покупка выполняется через Google Play. Это разовая покупка, не подписка.'
          : 'Purchase is handled by Google Play. This is a one-time unlock, not a subscription.';
    }
    return isRu
        ? 'Для публикации нужно создать managed product "$productId" в Play Console. Экспорт, импорт и базовая защита данных остаются доступными.'
        : 'Before publishing, create managed product "$productId" in Play Console. Export, import, and basic data protection remain available.';
  }

  List<_ProFeature> get features {
    if (isRu) {
      return const [
        _ProFeature(
          icon: Icons.backup_rounded,
          title: 'Расширенный backup',
          body: 'Напоминания о backup и более гибкие сценарии экспорта.',
        ),
        _ProFeature(
          icon: Icons.widgets_rounded,
          title: 'Виджеты',
          body: 'Быстрое добавление и возвращение к сохраненным фрагментам.',
        ),
        _ProFeature(
          icon: Icons.checklist_rounded,
          title: 'Batch actions',
          body: 'Массовые действия с записями и темами.',
        ),
        _ProFeature(
          icon: Icons.collections_bookmark_rounded,
          title: 'Коллекции',
          body: 'Сохраненные подборки и расширенная организация библиотеки.',
        ),
      ];
    }

    return const [
      _ProFeature(
        icon: Icons.backup_rounded,
        title: 'Advanced backup',
        body: 'Backup reminders and more flexible export workflows.',
      ),
      _ProFeature(
        icon: Icons.widgets_rounded,
        title: 'Widgets',
        body: 'Quick add and faster return to saved fragments.',
      ),
      _ProFeature(
        icon: Icons.checklist_rounded,
        title: 'Batch actions',
        body: 'Bulk operations for entries and topics.',
      ),
      _ProFeature(
        icon: Icons.collections_bookmark_rounded,
        title: 'Collections',
        body: 'Saved sets and deeper library organization.',
      ),
    ];
  }
}

class _ProFeature {
  const _ProFeature({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}
