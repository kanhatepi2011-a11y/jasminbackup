import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/secure_token_storage.dart';
import '../models/admin_user.dart';
import '../models/auth_session.dart';
import '../models/login_challenge.dart';
import 'auth_api.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    api: ref.watch(authApiProvider),
    tokenStorage: ref.watch(secureTokenStorageProvider),
  );
});

class AuthRepository {
  const AuthRepository({required AuthApi api, required SecureTokenStorage tokenStorage})
      : _api = api,
        _tokenStorage = tokenStorage;

  final AuthApi _api;
  final SecureTokenStorage _tokenStorage;

  Future<LoginChallenge> login(String email, String password) {
    return _api.login(email: email, password: password);
  }

  Future<AuthSession> verifyTwoFactor(String challengeId, String code) async {
    final session = await _api.verifyTwoFactor(challengeId: challengeId, code: code);
    await _tokenStorage.saveSession(token: session.token, expiresAt: session.expiresAt);
    return session;
  }

  Future<AdminUser> restoreSession() async {
    final hasToken = await _tokenStorage.hasValidLocalToken();
    if (!hasToken) {
      await _tokenStorage.clearSession();
      throw const FormatException('No valid local token.');
    }
    return _api.me();
  }

  Future<DateTime?> readLocalExpiry() {
    return _tokenStorage.readExpiry();
  }

  Future<void> clearLocalSession() {
    return _tokenStorage.clearSession();
  }

  Future<void> logout() async {
    await _api.logout();
    await _tokenStorage.clearSession();
  }
}
