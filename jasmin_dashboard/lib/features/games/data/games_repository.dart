import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../models/game_model.dart';
import '../models/game_payload.dart';
import 'games_api.dart';

final gamesRepositoryProvider = Provider<GamesRepository>((ref) {
  return GamesRepository(ref.watch(gamesApiProvider));
});

class GamesRepository {
  const GamesRepository(this._api);

  final GamesApi _api;

  Future<List<GameModel>> fetchGames() async {
    try {
      return await _api.fetchGames();
    } on DioException catch (error) {
      throw _exceptionFromDio(error, 'Could not load games. Check your connection and try again.');
    }
  }

  Future<GameModel> fetchGame(String id) async {
    try {
      return await _api.fetchGame(id);
    } on DioException catch (error) {
      throw _exceptionFromDio(error, 'Could not load this game. Pull to refresh and try again.');
    }
  }

  Future<GameModel> createGame(GamePayload payload) async {
    try {
      return await _api.createGame(payload);
    } on DioException catch (error) {
      throw _exceptionFromDio(error, 'Could not create this game. Please check the fields and try again.');
    }
  }

  Future<GameModel> updateGame(String id, GamePayload payload) async {
    try {
      return await _api.updateGame(id, payload);
    } on DioException catch (error) {
      throw _exceptionFromDio(error, 'Could not update this game. Please check the fields and try again.');
    }
  }

  Future<GameModel> setGameActive(String id, bool active) async {
    try {
      return await _api.setGameActive(id, active);
    } on DioException catch (error) {
      throw _exceptionFromDio(error, 'Could not update game visibility. Please try again.');
    }
  }

  Future<GameDeleteResult> deleteGame(String id) async {
    try {
      return await _api.deleteGame(id);
    } on DioException catch (error) {
      throw _exceptionFromDio(error, 'Could not delete this game. It may already be linked to products or orders.');
    }
  }

  Future<void> reorderGame(String id, String direction) async {
    try {
      await _api.reorderGame(id, direction);
    } on DioException catch (error) {
      throw _exceptionFromDio(error, 'Could not reorder this game. Please try again.');
    }
  }

  AppException _exceptionFromDio(DioException error, String fallback) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['error'] ?? data['message'];
      if (message != null) return AppException(message.toString(), statusCode: error.response?.statusCode);
    }
    return AppException(fallback, statusCode: error.response?.statusCode);
  }
}
