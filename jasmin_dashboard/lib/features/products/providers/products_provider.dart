import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/constants/refresh_intervals.dart';
import '../data/products_repository.dart';
import '../models/product_game_summary.dart';
import '../models/product_model.dart';
import '../models/product_payload.dart';

final productsProvider =
    StateNotifierProvider.autoDispose<ProductsController, ProductsState>((ref) {
  final controller = ProductsController(ref.watch(productsRepositoryProvider));
  controller.load();
  controller.startAutoRefresh();
  return controller;
});

class ProductsController extends StateNotifier<ProductsState> {
  ProductsController(this._repository) : super(const ProductsState());

  final ProductsRepository _repository;
  Timer? _autoRefreshTimer;

  Future<void> load({bool silent = false}) async {
    if (!mounted) {
      return;
    }
    state = state.copyWith(
      isLoading: !silent && state.products.isEmpty,
      isRefreshing: silent || state.products.isNotEmpty,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final results = await Future.wait<dynamic>([
        _repository.fetchProducts(
            gameId: state.gameId == 'ALL' ? null : state.gameId,
            active: state.activeValue),
        _repository.fetchGames(),
      ]);
      if (!mounted) {
        return;
      }
      state = state.copyWith(
        products: results[0] as List<ProductModel>,
        games: results[1] as List<ProductGameSummary>,
        isLoading: false,
        isRefreshing: false,
        lastUpdatedAt: DateTime.now(),
        clearError: true,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        errorMessage: _messageFromError(error),
      );
    }
  }

  Future<void> refresh() => load(silent: true);

  Future<void> setGameFilter(String gameId) async {
    state =
        state.copyWith(gameId: gameId, clearError: true, clearSuccess: true);
    await load();
  }

  Future<void> setActiveFilter(String activeFilter) async {
    state = state.copyWith(
        activeFilter: activeFilter, clearError: true, clearSuccess: true);
    await load();
  }

  void setQuery(String query) {
    state = state.copyWith(
        query: query.trim(), clearError: true, clearSuccess: true);
  }

  Future<void> toggleActive(ProductModel product) async {
    state = state.copyWith(
        actionProductId: product.id, clearError: true, clearSuccess: true);
    try {
      await _repository.setProductActive(product.id, !product.active);
      if (!mounted) {
        return;
      }
      state = state.copyWith(
        actionProductId: null,
        successMessage: !product.active
            ? '${product.name} is now visible on website.'
            : '${product.name} is now hidden from website.',
      );
      await load(silent: true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      state = state.copyWith(
          actionProductId: null, errorMessage: _messageFromError(error));
    }
  }

  Future<void> deleteProduct(ProductModel product) async {
    state = state.copyWith(
        actionProductId: product.id, clearError: true, clearSuccess: true);
    try {
      final result = await _repository.deleteProduct(product.id);
      if (!mounted) {
        return;
      }
      final message = result.deleted
          ? '${product.name} was deleted.'
          : '${product.name} has orders, so it was disabled instead of deleted.';
      state = state.copyWith(actionProductId: null, successMessage: message);
      await load(silent: true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      state = state.copyWith(
          actionProductId: null, errorMessage: _messageFromError(error));
    }
  }

  void startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(RefreshIntervals.contentManagement, (_) {
      if (mounted) {
        load(silent: true);
      }
    });
  }

  String _messageFromError(Object error) {
    if (error is AppException) {
      return error.message;
    }
    return 'Products refresh failed. Please try again.';
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }
}

class ProductsState {
  const ProductsState({
    this.products = const <ProductModel>[],
    this.games = const <ProductGameSummary>[],
    this.query = '',
    this.gameId = 'ALL',
    this.activeFilter = 'ALL',
    this.isLoading = false,
    this.isRefreshing = false,
    this.actionProductId,
    this.errorMessage,
    this.successMessage,
    this.lastUpdatedAt,
  });

  final List<ProductModel> products;
  final List<ProductGameSummary> games;
  final String query;
  final String gameId;
  final String activeFilter;
  final bool isLoading;
  final bool isRefreshing;
  final String? actionProductId;
  final String? errorMessage;
  final String? successMessage;
  final DateTime? lastUpdatedAt;

  bool get hasProducts => products.isNotEmpty;

  bool? get activeValue {
    switch (activeFilter) {
      case 'ACTIVE':
        return true;
      case 'INACTIVE':
        return false;
      default:
        return null;
    }
  }

  List<ProductModel> get filteredProducts {
    final text = query.trim().toLowerCase();
    if (text.isEmpty) {
      return products;
    }
    return products.where((product) {
      final haystack = [
        product.name,
        product.game.name,
        product.game.slug,
        product.badge ?? '',
        product.supplierCode ?? '',
        product.amount.toString(),
        product.priceUsd.toString(),
      ].join(' ').toLowerCase();
      return haystack.contains(text);
    }).toList();
  }

  ProductsState copyWith({
    List<ProductModel>? products,
    List<ProductGameSummary>? games,
    String? query,
    String? gameId,
    String? activeFilter,
    bool? isLoading,
    bool? isRefreshing,
    String? actionProductId,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
    DateTime? lastUpdatedAt,
  }) {
    return ProductsState(
      products: products ?? this.products,
      games: games ?? this.games,
      query: query ?? this.query,
      gameId: gameId ?? this.gameId,
      activeFilter: activeFilter ?? this.activeFilter,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      actionProductId: actionProductId,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      successMessage:
          clearSuccess ? null : successMessage ?? this.successMessage,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }
}

final productEditorProvider = StateNotifierProvider.autoDispose
    .family<ProductEditorController, ProductEditorState, String?>(
        (ref, productId) {
  final controller =
      ProductEditorController(ref.watch(productsRepositoryProvider), productId);
  controller.load();
  return controller;
});

class ProductEditorController extends StateNotifier<ProductEditorState> {
  ProductEditorController(this._repository, this.productId)
      : super(const ProductEditorState());

  final ProductsRepository _repository;
  final String? productId;

  bool get isEditing => productId != null && productId!.trim().isNotEmpty;

  Future<void> load() async {
    if (!mounted) {
      return;
    }
    state =
        state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      final games = await _repository.fetchGames();
      ProductModel? product;
      if (isEditing) {
        product = await _repository.fetchProduct(productId!);
      }
      if (!mounted) {
        return;
      }
      state = state.copyWith(
        games: games,
        product: product,
        isLoading: false,
        clearError: true,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      state = state.copyWith(
          isLoading: false, errorMessage: _messageFromError(error));
    }
  }

  Future<ProductModel?> save(ProductPayload payload) async {
    if (!mounted) {
      return null;
    }
    state =
        state.copyWith(isSaving: true, clearError: true, clearSuccess: true);
    try {
      final result = isEditing
          ? await _repository.updateProduct(productId!, payload)
          : await _repository.createProduct(payload);
      if (!mounted) {
        return result;
      }
      state = state.copyWith(
        product: result,
        isSaving: false,
        successMessage: isEditing
            ? 'Package updated. Website will refresh shortly.'
            : 'Package created. Website will refresh shortly.',
      );
      return result;
    } catch (error) {
      if (!mounted) {
        return null;
      }
      state = state.copyWith(
          isSaving: false, errorMessage: _messageFromError(error));
      return null;
    }
  }

  String _messageFromError(Object error) {
    if (error is AppException) {
      return error.message;
    }
    return 'Product action failed. Please try again.';
  }
}

class ProductEditorState {
  const ProductEditorState({
    this.games = const <ProductGameSummary>[],
    this.product,
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
  });

  final List<ProductGameSummary> games;
  final ProductModel? product;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;

  ProductEditorState copyWith({
    List<ProductGameSummary>? games,
    ProductModel? product,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return ProductEditorState(
      games: games ?? this.games,
      product: product ?? this.product,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      successMessage:
          clearSuccess ? null : successMessage ?? this.successMessage,
    );
  }
}
