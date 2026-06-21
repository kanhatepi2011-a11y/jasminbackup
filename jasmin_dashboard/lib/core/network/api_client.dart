import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/api_config.dart';
import '../storage/secure_token_storage.dart';
import 'auth_interceptor.dart';

final dioProvider = Provider<Dio>((ref) {
  final tokenStorage = ref.watch(secureTokenStorageProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    AuthInterceptor(
      tokenStorage,
      onUnauthorized: () async {
        final notifier = ref.read(authUnauthorizedEventProvider.notifier);
        notifier.state = notifier.state + 1;
      },
    ),
  );
  return dio;
});
