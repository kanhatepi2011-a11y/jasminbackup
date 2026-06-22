import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/api_paths.dart';
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
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _tokenStorage.readToken();
    if (token != null && token.isNotEmpty && _shouldAttachBearer(options)) {
      options.headers['Authorization'] = 'Bearer $token';
      options.headers['X-Admin-Session-Token'] = token;
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final hadBearerToken = (err.requestOptions.headers['Authorization']
                ?.toString()
                .startsWith('Bearer ') ??
            false) ||
        (err.requestOptions.headers['X-Admin-Session-Token']
                ?.toString()
                .isNotEmpty ??
            false);

    if (err.response?.statusCode == 401 && hadBearerToken) {
      await onUnauthorized();
    }

    handler.next(err);
  }

  bool _shouldAttachBearer(RequestOptions options) {
    final path = _pathFrom(options);
    if (!path.contains('/api/admin')) return false;

    return !path.endsWith(ApiPaths.login) && !path.endsWith(ApiPaths.twoFactor);
  }

  String _pathFrom(RequestOptions options) {
    final uriPath = options.uri.path;
    if (uriPath.isNotEmpty) return uriPath;
    final parsed = Uri.tryParse(options.path);
    final parsedPath = parsed?.path;
    if (parsedPath != null && parsedPath.isNotEmpty) return parsedPath;
    return options.path;
  }
}
