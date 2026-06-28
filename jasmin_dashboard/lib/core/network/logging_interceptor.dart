import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../config/api_config.dart';

/// Logs request URL, status code, and error type — debug builds only.
/// Never logs headers, tokens, or request/response bodies, to avoid leaking
/// secrets into device logs.
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (ApiConfig.enableDebugLogs) {
      developer.log('-> ${options.method} ${options.uri}', name: 'API');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (ApiConfig.enableDebugLogs) {
      developer.log(
        '<- ${response.statusCode} ${response.requestOptions.uri}',
        name: 'API',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (ApiConfig.enableDebugLogs) {
      developer.log(
        'x ${err.type.name} '
        '(${err.response?.statusCode ?? "no status"}) '
        '${err.requestOptions.uri}',
        name: 'API',
      );
    }
    handler.next(err);
  }
}
