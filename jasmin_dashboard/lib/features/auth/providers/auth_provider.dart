import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/network/auth_interceptor.dart';
import '../data/auth_repository.dart';
import '../models/auth_state.dart';

final authProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  final controller = AuthController(ref.watch(authRepositoryProvider));

  ref.listen<int>(authUnauthorizedEventProvider, (previous, next) {
    if (previous != null && next > previous) {
      controller.handleUnauthorized();
    }
  });

  return controller;
});

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository) : super(AuthState.checking()) {
    checkSession();
  }

  final AuthRepository _repository;
  Timer? _challengeTimer;
  Timer? _sessionExpiryTimer;

  Future<void> checkSession() async {
    _cancelTimers();
    state = AuthState.checking();

    try {
      final admin = await _repository.restoreSession();
      final expiresAt = await _repository.readLocalExpiry();
      _scheduleSessionExpiry(expiresAt);
      state = AuthState(status: AuthStatus.authenticated, admin: admin);
    } catch (_) {
      await _repository.clearLocalSession();
      state = AuthState.unauthenticated();
    }
  }

  Future<bool> login(String email, String password) async {
    _challengeTimer?.cancel();
    state = AuthState.unauthenticated().copyWith(isLoading: true, clearError: true, clearInfo: true);

    try {
      final challenge = await _repository.login(email, password);
      if (!challenge.requires2FA || challenge.challengeId.isEmpty) {
        state = AuthState.unauthenticated(
          errorMessage: 'Login response is missing Google Authenticator challenge. Please try again.',
        );
        return false;
      }

      _scheduleChallengeExpiry(challenge.expiresAt);
      state = AuthState(
        status: AuthStatus.awaitingTwoFactor,
        challengeId: challenge.challengeId,
        challengeExpiresAt: challenge.expiresAt,
        loginEmail: email.trim().toLowerCase(),
        infoMessage: 'Password verified. Enter your Google Authenticator code.',
      );
      return true;
    } catch (error) {
      state = AuthState.unauthenticated(
        errorMessage: _messageFromError(error, fallback: 'Invalid login credentials.'),
      );
      return false;
    }
  }

  Future<bool> verifyTwoFactor(String code) async {
    final challengeId = state.challengeId;
    if (challengeId == null || challengeId.isEmpty || !state.hasValidChallenge) {
      _challengeTimer?.cancel();
      state = AuthState.unauthenticated(
        errorMessage: '2FA session expired. Please login again.',
      );
      return false;
    }

    final normalizedCode = code.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(normalizedCode)) {
      state = state.copyWith(
        errorMessage: 'Enter the 6-digit Google Authenticator code.',
        isLoading: false,
        clearInfo: true,
      );
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true, clearInfo: true);
    try {
      final session = await _repository.verifyTwoFactor(challengeId, normalizedCode);
      _challengeTimer?.cancel();
      _scheduleSessionExpiry(session.expiresAt);
      state = AuthState(status: AuthStatus.authenticated, admin: session.admin);
      return true;
    } catch (error) {
      state = state.copyWith(
        status: AuthStatus.awaitingTwoFactor,
        isLoading: false,
        errorMessage: _messageFromError(error, fallback: 'Invalid Google Authenticator code.'),
        clearInfo: true,
      );
      return false;
    }
  }

  Future<void> resetToLogin({String? message}) async {
    _challengeTimer?.cancel();
    await _repository.clearLocalSession();
    state = AuthState.unauthenticated(infoMessage: message);
  }

  Future<void> handleUnauthorized() async {
    _cancelTimers();
    await _repository.clearLocalSession();
    if (!mounted) return;
    state = AuthState.unauthenticated(
      errorMessage: 'Session expired. Please login again.',
    );
  }

  Future<void> logout() async {
    final current = state;
    state = current.copyWith(isLoading: true, clearError: true, clearInfo: true);
    await _repository.logout();
    _cancelTimers();
    if (!mounted) return;
    state = AuthState.unauthenticated(infoMessage: 'You have been logged out safely.');
  }

  void _scheduleChallengeExpiry(DateTime expiresAt) {
    _challengeTimer?.cancel();
    final duration = expiresAt.difference(DateTime.now().toUtc());
    if (duration.isNegative) {
      state = AuthState.unauthenticated(errorMessage: '2FA session expired. Please login again.');
      return;
    }

    _challengeTimer = Timer(duration, () {
      if (!mounted || state.status != AuthStatus.awaitingTwoFactor) return;
      state = AuthState.unauthenticated(errorMessage: '2FA session expired. Please login again.');
    });
  }

  void _scheduleSessionExpiry(DateTime? expiresAt) {
    _sessionExpiryTimer?.cancel();
    if (expiresAt == null) return;

    final duration = expiresAt.difference(DateTime.now().toUtc());
    if (duration.isNegative) {
      handleUnauthorized();
      return;
    }

    _sessionExpiryTimer = Timer(duration, () {
      handleUnauthorized();
    });
  }

  void _cancelTimers() {
    _challengeTimer?.cancel();
    _sessionExpiryTimer?.cancel();
  }

  String _messageFromError(Object error, {required String fallback}) {
    if (error is AppException) return error.message;
    return fallback;
  }

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }
}
