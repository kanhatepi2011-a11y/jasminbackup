import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_paths.dart';
import '../../../core/network/api_client.dart';
import '../models/public_data_version.dart';

final publicVersionApiProvider = Provider<PublicVersionApi>((ref) => PublicVersionApi(ref.watch(dioProvider)));

class PublicVersionApi {
  const PublicVersionApi(this._dio);

  final Dio _dio;

  Future<PublicDataVersion> fetchVersion({
    required String scope,
    String? slug,
    String? orderNumber,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.publicVersion,
      queryParameters: <String, dynamic>{
        'scope': scope,
        if (slug != null && slug.trim().isNotEmpty) 'slug': slug.trim(),
        if (orderNumber != null && orderNumber.trim().isNotEmpty) 'orderNumber': orderNumber.trim(),
      },
    );

    return PublicDataVersion.fromJson(response.data ?? const <String, dynamic>{});
  }
}
