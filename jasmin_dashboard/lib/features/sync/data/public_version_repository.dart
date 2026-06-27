import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../models/public_data_version.dart';
import 'public_version_api.dart';

final publicVersionRepositoryProvider = Provider<PublicVersionRepository>(
  (ref) => PublicVersionRepository(ref.watch(publicVersionApiProvider)),
);

class PublicVersionRepository {
  const PublicVersionRepository(this._api);

  final PublicVersionApi _api;

  Future<PublicDataVersion> fetchVersion(
      {required String scope, String? slug, String? orderNumber}) async {
    try {
      return await _api.fetchVersion(
          scope: scope, slug: slug, orderNumber: orderNumber);
    } on DioException catch (error) {
      final data = error.response?.data;
      if (data is Map && data['error'] != null) {
        throw AppException(data['error'].toString(),
            statusCode: error.response?.statusCode);
      }
      throw AppException('Could not check website update status.',
          statusCode: error.response?.statusCode);
    }
  }
}
