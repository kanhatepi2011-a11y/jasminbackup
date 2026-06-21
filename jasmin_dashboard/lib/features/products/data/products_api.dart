import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_paths.dart';
import '../../../core/network/api_client.dart';
import '../models/product_game_summary.dart';
import '../models/product_model.dart';
import '../models/product_payload.dart';

final productsApiProvider = Provider<ProductsApi>((ref) {
  return ProductsApi(ref.watch(dioProvider));
});

class ProductsApi {
  const ProductsApi(this._dio);

  final Dio _dio;

  Future<List<ProductModel>> fetchProducts({
    String? gameId,
    bool? active,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      ApiPaths.products,
      queryParameters: {
        if (gameId != null && gameId.trim().isNotEmpty) 'gameId': gameId.trim(),
        if (active != null) 'active': active.toString(),
      },
    );

    return (response.data ?? const <dynamic>[])
        .whereType<Map>()
        .map((item) => ProductModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<ProductGameSummary>> fetchGames() async {
    final response = await _dio.get<List<dynamic>>(ApiPaths.games);
    return (response.data ?? const <dynamic>[])
        .whereType<Map>()
        .map((item) => ProductGameSummary.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<ProductModel> fetchProduct(String id) async {
    final response = await _dio.get<Map<String, dynamic>>(ApiPaths.productDetail(id));
    return ProductModel.fromJson(response.data ?? const <String, dynamic>{});
  }

  Future<ProductModel> createProduct(ProductPayload payload) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.products,
      data: payload.toJson(),
    );
    return ProductModel.fromJson(response.data ?? const <String, dynamic>{});
  }

  Future<ProductModel> updateProduct(String id, ProductPayload payload) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      ApiPaths.productDetail(id),
      data: payload.toJson(),
    );
    return ProductModel.fromJson(response.data ?? const <String, dynamic>{});
  }

  Future<ProductDeleteResult> deleteProduct(String id) async {
    final response = await _dio.delete<Map<String, dynamic>>(ApiPaths.productDetail(id));
    final data = response.data ?? const <String, dynamic>{};
    return ProductDeleteResult(
      ok: data['ok'] == true,
      deleted: data['deleted'] == true,
      disabled: data['disabled'] is Map
          ? ProductModel.fromJson(Map<String, dynamic>.from(data['disabled'] as Map))
          : null,
    );
  }

  Future<ProductModel> setProductActive(String id, bool active) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      ApiPaths.productDetail(id),
      data: <String, dynamic>{'active': active},
    );
    return ProductModel.fromJson(response.data ?? const <String, dynamic>{});
  }
}

class ProductDeleteResult {
  const ProductDeleteResult({
    required this.ok,
    required this.deleted,
    required this.disabled,
  });

  final bool ok;
  final bool deleted;
  final ProductModel? disabled;
}
