import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/api_error_mapper.dart';
import '../models/product_game_summary.dart';
import '../models/product_model.dart';
import '../models/product_payload.dart';
import 'products_api.dart';

final productsRepositoryProvider = Provider<ProductsRepository>((ref) {
  return ProductsRepository(ref.watch(productsApiProvider));
});

class ProductsRepository {
  const ProductsRepository(this._api);

  final ProductsApi _api;

  Future<List<ProductModel>> fetchProducts(
      {String? gameId, bool? active}) async {
    try {
      return await _api.fetchProducts(gameId: gameId, active: active);
    } on DioException catch (error) {
      throw _exceptionFromDio(error,
          'Could not load products. Check your connection and try again.');
    }
  }

  Future<List<ProductGameSummary>> fetchGames() async {
    try {
      return await _api.fetchGames();
    } on DioException catch (error) {
      throw _exceptionFromDio(
          error, 'Could not load games for product management.');
    }
  }

  Future<ProductModel> fetchProduct(String id) async {
    try {
      return await _api.fetchProduct(id);
    } on DioException catch (error) {
      throw _exceptionFromDio(
          error, 'Could not load this product. Pull to refresh and try again.');
    }
  }

  Future<ProductModel> createProduct(ProductPayload payload) async {
    try {
      return await _api.createProduct(payload);
    } on DioException catch (error) {
      throw _exceptionFromDio(error,
          'Could not create this package. Please check the fields and try again.');
    }
  }

  Future<ProductModel> updateProduct(String id, ProductPayload payload) async {
    try {
      return await _api.updateProduct(id, payload);
    } on DioException catch (error) {
      throw _exceptionFromDio(error,
          'Could not update this package. Please check the fields and try again.');
    }
  }

  Future<ProductDeleteResult> deleteProduct(String id) async {
    try {
      return await _api.deleteProduct(id);
    } on DioException catch (error) {
      throw _exceptionFromDio(error,
          'Could not delete this package. It may already be linked to orders.');
    }
  }

  Future<ProductModel> setProductActive(String id, bool active) async {
    try {
      return await _api.setProductActive(id, active);
    } on DioException catch (error) {
      throw _exceptionFromDio(
          error, 'Could not update product visibility. Please try again.');
    }
  }

  AppException _exceptionFromDio(DioException error, String fallback) {
    return mapDioError(error, fallback: fallback);
  }
}
