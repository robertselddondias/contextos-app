// lib/services/purchase_manager.dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gerencia as compras in-app do aplicativo
class PurchaseManager {
  // Singleton
  static final PurchaseManager _instance = PurchaseManager._internal();
  factory PurchaseManager() => _instance;
  PurchaseManager._internal();

  // IDs dos produtos
  static const String _removeAdsId = 'remove_ads';

  // Conjunto de IDs de produtos para consulta
  static final Set<String> _productIds = {_removeAdsId};

  // API de compras
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;

  // Status
  bool _isAvailable = false;
  bool _isInitialized = false;
  bool _purchasePending = false;
  bool _removeAdsActive = false;

  // Lista de produtos disponíveis
  List<ProductDetails> _products = [];

  // Stream para notificar mudanças no estado das compras
  final StreamController<bool> _purchaseStateController = StreamController<bool>.broadcast();
  Stream<bool> get purchaseStateStream => _purchaseStateController.stream;

  // Subscrição para eventos de compra
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  // Getters
  bool get isAvailable => _isAvailable;
  bool get isInitialized => _isInitialized;
  bool get purchasePending => _purchasePending;
  bool get removeAdsActive => _removeAdsActive;
  List<ProductDetails> get products => _products;

  /// Inicializa o serviço de compras
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Verificar se as compras in-app estão disponíveis
    _isAvailable = await _inAppPurchase.isAvailable();

    if (!_isAvailable) {
      _isInitialized = true;
      if (kDebugMode) {
        print('Compras in-app não disponíveis neste dispositivo');
      }
      return;
    }

    // Configurar o listener para as compras
    _subscription = _inAppPurchase.purchaseStream.listen(_listenToPurchaseUpdated);

    // Carregar produtos disponíveis
    await _loadProducts();

    // Verificar compras existentes
    await _restorePurchases();

    // Carregar o estado "remover anúncios" das preferências
    await _loadRemoveAdsState();

    _isInitialized = true;
    if (kDebugMode) {
      print('PurchaseManager inicializado com sucesso');
    }
  }

  /// Carrega os produtos disponíveis para compra
  Future<void> _loadProducts() async {
    try {
      final ProductDetailsResponse response =
      await _inAppPurchase.queryProductDetails(_productIds);

      if (response.notFoundIDs.isNotEmpty) {
        if (kDebugMode) {
          print('Produtos não encontrados: ${response.notFoundIDs}');
        }
      }

      _products = response.productDetails;

      if (kDebugMode) {
        print('Produtos disponíveis: ${_products.length}');
        for (final product in _products) {
          print(' - ${product.id}: ${product.title} - ${product.price}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao carregar produtos: $e');
      }
    }
  }

  /// Restaura as compras anteriores do usuário
  Future<void> _restorePurchases() async {
    try {
      if (Platform.isIOS) {
        await _inAppPurchase.restorePurchases();
      } else {
        // No Android, podemos verificar o histórico de compras chamando o método restore
        // (a biblioteca trata isso internamente)
        await _inAppPurchase.restorePurchases();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao restaurar compras: $e');
      }
    }
  }

  /// Carrega o estado "remover anúncios" das preferências
  Future<void> _loadRemoveAdsState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _removeAdsActive = prefs.getBool('remove_ads_active') ?? false;

      // Notificar ouvintes
      _notifyStateChange();

      if (kDebugMode) {
        print('Estado remove_ads_active carregado: $_removeAdsActive');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao carregar estado remover anúncios: $e');
      }
    }
  }

  /// Salva o estado "remover anúncios" nas preferências
  Future<void> _saveRemoveAdsState(bool isActive) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('remove_ads_active', isActive);

      _removeAdsActive = isActive;

      // Notificar ouvintes
      _notifyStateChange();

      if (kDebugMode) {
        print('Estado remove_ads_active salvo: $isActive');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao salvar estado remover anúncios: $e');
      }
    }
  }

  /// Inicia uma compra
  Future<bool> buyRemoveAds() async {
    if (!_isAvailable || _purchasePending) {
      return false;
    }

    // Buscar o produto
    final ProductDetails? product = _findProductById(_removeAdsId);
    if (product == null) {
      if (kDebugMode) {
        print('Produto $_removeAdsId não disponível');
      }
      return false;
    }

    try {
      _purchasePending = true;

      // Inicia a compra
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
      );

      return await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );
    } catch (e) {
      _purchasePending = false;
      if (kDebugMode) {
        print('Erro ao iniciar compra: $e');
      }
      return false;
    }
  }

  /// Restaura as compras do usuário
  Future<void> restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao restaurar compras: $e');
      }
    }
  }

  /// Encontra um produto pelo ID
  ProductDetails? _findProductById(String id) {
    try {
      return _products.firstWhere((product) => product.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Processa as atualizações de compra
  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        _updatePurchasePending(true);
      } else {
        _updatePurchasePending(false);

        if (purchaseDetails.status == PurchaseStatus.error) {
          _handlePurchaseError(purchaseDetails);
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          _verifyPurchase(purchaseDetails);
        }

        // Completar a transação
        if (purchaseDetails.pendingCompletePurchase) {
          _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
    }
  }

  /// Atualiza o estado pendente da compra
  void _updatePurchasePending(bool isPending) {
    _purchasePending = isPending;
    // Notificar ouvintes se necessário
  }

  /// Manipula erros de compra
  void _handlePurchaseError(PurchaseDetails purchaseDetails) {
    if (kDebugMode) {
      print('Erro na compra: ${purchaseDetails.error?.message}');
    }
    // Poderia exibir mensagem de erro ao usuário por meio de um StreamController
  }

  /// Verifica se a compra é válida
  void _verifyPurchase(PurchaseDetails purchaseDetails) {
    // Verifica se é o produto "remover anúncios"
    if (purchaseDetails.productID == _removeAdsId) {
      // Ativa a remoção de anúncios
      _saveRemoveAdsState(true);

      if (kDebugMode) {
        print('Compra de remover anúncios verificada e ativada');
      }
    }
  }

  /// Notifica alterações no estado das compras
  void _notifyStateChange() {
    _purchaseStateController.add(_removeAdsActive);
  }

  /// Libera recursos
  void dispose() {
    _subscription?.cancel();
    _purchaseStateController.close();
  }
}
