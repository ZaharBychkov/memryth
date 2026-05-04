import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

class ProPurchaseService {
  ProPurchaseService({InAppPurchase? inAppPurchase, String? productId})
    : _inAppPurchase = inAppPurchase ?? InAppPurchase.instance,
      productId = productId ?? defaultProductId;

  static const defaultProductId = String.fromEnvironment(
    'MEMRYTH_PRO_PRODUCT_ID',
    defaultValue: 'memryth_pro',
  );

  final InAppPurchase _inAppPurchase;
  final String productId;

  Stream<List<PurchaseDetails>> get purchaseStream =>
      _inAppPurchase.purchaseStream;

  Future<ProProductStatus> loadProduct() async {
    if (productId.trim().isEmpty) {
      return const ProProductStatus(productId: '', productConfigured: false);
    }

    final storeAvailable = await _inAppPurchase.isAvailable();
    if (!storeAvailable) {
      return ProProductStatus(
        productId: productId,
        storeAvailable: false,
        productConfigured: true,
      );
    }

    final response = await _inAppPurchase.queryProductDetails({productId});
    return ProProductStatus(
      productId: productId,
      storeAvailable: true,
      productConfigured: true,
      product: response.productDetails.isEmpty
          ? null
          : response.productDetails.first,
      notFoundIds: response.notFoundIDs,
      errorMessage: response.error?.message,
    );
  }

  Future<bool> buyPro(ProductDetails product) {
    return _inAppPurchase.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
    );
  }

  Future<void> restorePurchases() => _inAppPurchase.restorePurchases();

  Future<void> completePurchase(PurchaseDetails purchase) {
    return _inAppPurchase.completePurchase(purchase);
  }

  bool isCompletedProPurchase(PurchaseDetails purchase) {
    return purchase.productID == productId &&
        (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored);
  }
}

class ProProductStatus {
  const ProProductStatus({
    required this.productId,
    this.storeAvailable = false,
    this.productConfigured = true,
    this.product,
    this.notFoundIds = const [],
    this.errorMessage,
  });

  final String productId;
  final bool storeAvailable;
  final bool productConfigured;
  final ProductDetails? product;
  final List<String> notFoundIds;
  final String? errorMessage;

  bool get canPurchase =>
      productConfigured && storeAvailable && product != null;
}
