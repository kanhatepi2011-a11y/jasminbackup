import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/constants/refresh_intervals.dart';
import '../data/games_repository.dart';
import '../models/game_model.dart';
import '../models/game_payload.dart';

final gamesProvider =
    StateNotifierProvider.autoDispose<GamesController, GamesState>((ref) {
  final controller = GamesController(ref.watch(gamesRepositoryProvider));
  controller.load();
  controller.startAutoRefresh();
  return controller;
});

class GamesController extends StateNotifier<GamesState> {
  GamesController(this._repository) : super(const GamesState());

  final GamesRepository _repository;
  Timer? _autoRefreshTimer;

  Future<void> load({bool silent = false}) async {
    if (!mounted) {
      return;
    }
    state = state.copyWith(
      isLoading: !silent && state.games.isEmpty,
      isRefreshing: silent || state.games.isNotEmpty,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final games = await _repository.fetchGames();
      if (!mounted) {
        return;
      }
      state = state.copyWith(
        games: games,
        isLoading: false,
        isRefreshing: false,
        lastUpdatedAt: DateTime.now(),
        clearError: true,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        errorMessage: _messageFromError(error),
      );
    }
  }

  Future<void> refresh() => load(silent: true);

  void setQuery(String query) {
    state = state.copyWith(
        query: query.trim(), clearError: true, clearSuccess: true);
  }

  void setActiveFilter(String activeFilter) {
    state = state.copyWith(
        activeFilter: activeFilter, clearError: true, clearSuccess: true);
  }

  void setFeaturedFilter(String featuredFilter) {
    state = state.copyWith(
        featuredFilter: featuredFilter, clearError: true, clearSuccess: true);
  }

  Future<void> toggleActive(GameModel game) async {
    state = state.copyWith(
        actionGameId: game.id, clearError: true, clearSuccess: true);
    try {
      await _repository.setGameActive(game.id, !game.active);
      if (!mounted) {
        return;
      }
      state = state.copyWith(
        actionGameId: null,
        successMessage: !game.active
            ? '${game.safeName} is now visible on JASMINTOPUP.'
            : '${game.safeName} is now hidden from JASMINTOPUP.',
      );
      await load(silent: true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      state = state.copyWith(
          actionGameId: null, errorMessage: _messageFromError(error));
    }
  }

  Future<void> deleteGame(GameModel game) async {
    state = state.copyWith(
        actionGameId: game.id, clearError: true, clearSuccess: true);
    try {
      final result = await _repository.deleteGame(game.id);
      if (!mounted) {
        return;
      }
      final message = result.deleted
          ? '${game.safeName} was deleted.'
          : '${game.safeName} has products/orders, so it was disabled instead of deleted.';
      state = state.copyWith(actionGameId: null, successMessage: message);
      await load(silent: true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      state = state.copyWith(
          actionGameId: null, errorMessage: _messageFromError(error));
    }
  }

  Future<void> reorder(GameModel game, String direction) async {
    state = state.copyWith(
        actionGameId: game.id, clearError: true, clearSuccess: true);
    try {
      await _repository.reorderGame(game.id, direction);
      if (!mounted) {
        return;
      }
      state = state.copyWith(
          actionGameId: null,
          successMessage: '${game.safeName} order updated.');
      await load(silent: true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      state = state.copyWith(
          actionGameId: null, errorMessage: _messageFromError(error));
    }
  }

  void startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(RefreshIntervals.contentManagement, (_) {
      if (mounted) {
        load(silent: true);
      }
    });
  }

  String _messageFromError(Object error) {
    if (error is AppException) {
      return error.message;
    }
    return 'Games refresh failed. Please try again.';
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }
}

class GamesState {
  const GamesState({
    this.games = const <GameModel>[],
    this.query = '',
    this.activeFilter = 'ALL',
    this.featuredFilter = 'ALL',
    this.isLoading = false,
    this.isRefreshing = false,
    this.actionGameId,
    this.errorMessage,
    this.successMessage,
    this.lastUpdatedAt,
  });

  final List<GameModel> games;
  final String query;
  final String activeFilter;
  final String featuredFilter;
  final bool isLoading;
  final bool isRefreshing;
  final String? actionGameId;
  final String? errorMessage;
  final String? successMessage;
  final DateTime? lastUpdatedAt;

  bool get hasGames => games.isNotEmpty;

  List<GameModel> get filteredGames {
    final text = query.trim().toLowerCase();
    return games.where((game) {
      final matchesActive = activeFilter == 'ALL' ||
          (activeFilter == 'ACTIVE' ? game.active : !game.active);
      final matchesFeatured = featuredFilter == 'ALL' ||
          (featuredFilter == 'FEATURED' ? game.featured : !game.featured);
      if (!matchesActive || !matchesFeatured) {
        return false;
      }
      if (text.isEmpty) {
        return true;
      }
      final haystack = [
        game.name,
        game.slug,
        game.publisher,
        game.currencyName,
        game.uidLabel,
        game.description ?? '',
      ].join(' ').toLowerCase();
      return haystack.contains(text);
    }).toList();
  }

  GamesState copyWith({
    List<GameModel>? games,
    String? query,
    String? activeFilter,
    String? featuredFilter,
    bool? isLoading,
    bool? isRefreshing,
    String? actionGameId,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
    DateTime? lastUpdatedAt,
  }) {
    return GamesState(
      games: games ?? this.games,
      query: query ?? this.query,
      activeFilter: activeFilter ?? this.activeFilter,
      featuredFilter: featuredFilter ?? this.featuredFilter,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      actionGameId: actionGameId,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      successMessage:
          clearSuccess ? null : successMessage ?? this.successMessage,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }
}

final gameEditorProvider = StateNotifierProvider.autoDispose
    .family<GameEditorController, GameEditorState, String?>((ref, gameId) {
  final controller =
      GameEditorController(ref.watch(gamesRepositoryProvider), gameId);
  controller.load();
  return controller;
});

class GameEditorController extends StateNotifier<GameEditorState> {
  GameEditorController(this._repository, this.gameId)
      : super(const GameEditorState());

  final GamesRepository _repository;
  final String? gameId;

  bool get isEditing => gameId != null && gameId!.trim().isNotEmpty;

  Future<void> load() async {
    if (!mounted) {
      return;
    }
    state =
        state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      GameModel? game;
      if (isEditing) {
        game = await _repository.fetchGame(gameId!);
      }
      if (!mounted) {
        return;
      }
      state = state.copyWith(game: game, isLoading: false, clearError: true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      state = state.copyWith(
          isLoading: false, errorMessage: _messageFromError(error));
    }
  }

  Future<GameModel?> save(GamePayload payload) async {
    if (!mounted) {
      return null;
    }
    state =
        state.copyWith(isSaving: true, clearError: true, clearSuccess: true);
    try {
      final result = isEditing
          ? await _repository.updateGame(gameId!, payload)
          : await _repository.createGame(payload);
      if (!mounted) {
        return result;
      }
      state = state.copyWith(
        game: result,
        isSaving: false,
        successMessage: isEditing
            ? 'Game updated. Website will refresh shortly.'
            : 'Game created. Website will refresh shortly.',
      );
      return result;
    } catch (error) {
      if (!mounted) {
        return null;
      }
      state = state.copyWith(
          isSaving: false, errorMessage: _messageFromError(error));
      return null;
    }
  }

  String _messageFromError(Object error) {
    if (error is AppException) {
      return error.message;
    }
    return 'Game action failed. Please try again.';
  }
}

class GameEditorState {
  const GameEditorState({
    this.game,
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
  });

  final GameModel? game;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;

  GameEditorState copyWith({
    GameModel? game,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return GameEditorState(
      game: game ?? this.game,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      successMessage:
          clearSuccess ? null : successMessage ?? this.successMessage,
    );
  }
}
