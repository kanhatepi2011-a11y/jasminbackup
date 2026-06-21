import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/secure_token_storage.dart';

final authUnauthorizedEventProvider = StateProvider<int>((ref) => 0);

class AuthInterceptor extends Interceptor {
  AuthInterceptor(
    this._tokenStorage, {
    required this.onUnauthorized,
  });

  final SecureTokenStorage _tokenStorage;
  final Future<void> Function() onUnauthorized;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _tokenStorage.readToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final hadBearerToken = (err.requestOptions.headers['Authorization']?.toString().startsWith('Bearer ') ?? false);

    if (err.response?.statusCode == 401 && hadBearerToken) {
      await _tokenStorage.clearSession();
      await onUnauthorized();
    }

    handler.next(err);
  }
}
