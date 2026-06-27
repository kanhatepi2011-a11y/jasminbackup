import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_paths.dart';
import '../../../core/network/api_client.dart';
import '../models/game_model.dart';
import '../models/game_payload.dart';

final gamesApiProvider = Provider<GamesApi>((ref) {
  return GamesApi(ref.watch(dioProvider));
});

class GamesApi {
  const GamesApi(this._dio);

  final Dio _dio;

  Future<List<GameModel>> fetchGames() async {
    final response = await _dio.get<List<dynamic>>(ApiPaths.games);
    return (response.data ?? const <dynamic>[])
        .whereType<Map>()
        .map((item) => GameModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<GameModel> fetchGame(String id) async {
    final response =
        await _dio.get<Map<String, dynamic>>(ApiPaths.gameDetail(id));
    return GameModel.fromJson(response.data ?? const <String, dynamic>{});
  }

  Future<GameModel> createGame(GamePayload payload) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.games,
      data: payload.toJson(),
    );
    return GameModel.fromJson(response.data ?? const <String, dynamic>{});
  }

  Future<GameModel> updateGame(String id, GamePayload payload) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      ApiPaths.gameDetail(id),
      data: payload.toJson(),
    );
    return GameModel.fromJson(response.data ?? const <String, dynamic>{});
  }

  Future<GameModel> setGameActive(String id, bool active) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      ApiPaths.gameDetail(id),
      data: <String, dynamic>{'active': active},
    );
    return GameModel.fromJson(response.data ?? const <String, dynamic>{});
  }

  Future<GameDeleteResult> deleteGame(String id) async {
    final response =
        await _dio.delete<Map<String, dynamic>>(ApiPaths.gameDetail(id));
    final data = response.data ?? const <String, dynamic>{};
    return GameDeleteResult(
      ok: data['ok'] == true,
      deleted: data['deleted'] == true,
      disabled: data['disabled'] is Map
          ? GameModel.fromJson(
              Map<String, dynamic>.from(data['disabled'] as Map))
          : null,
    );
  }

  Future<void> reorderGame(String id, String direction) async {
    await _dio.post<Map<String, dynamic>>(
      ApiPaths.gameReorder,
      data: <String, dynamic>{'id': id, 'direction': direction},
    );
  }
}

class GameDeleteResult {
  const GameDeleteResult({
    required this.ok,
    required this.deleted,
    required this.disabled,
  });

  final bool ok;
  final bool deleted;
  final GameModel? disabled;
}
