import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';

final secureTokenStorageProvider = Provider<SecureTokenStorage>((ref) {
  return const SecureTokenStorage();
});

class SecureTokenStorage {
  const SecureTokenStorage();

  static String? _cachedToken;
  static DateTime? _cachedExpiry;

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  Future<void> saveSession({
    required String token,
    required DateTime expiresAt,
  }) async {
    _cachedToken = token;
    _cachedExpiry = expiresAt;
    await _storage.write(key: AppConstants.tokenKey, value: token);
    await _storage.write(
      key: AppConstants.tokenExpiryKey,
      value: expiresAt.toIso8601String(),
    );
  }

  Future<String?> readToken() async {
    final cached = _cachedToken;
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    final token = await _storage.read(key: AppConstants.tokenKey);
    if (token != null && token.isNotEmpty) {
      _cachedToken = token;
    }
    return token;
  }

  Future<DateTime?> readExpiry() async {
    final cached = _cachedExpiry;
    if (cached != null) {
      return cached;
    }

    final raw = await _storage.read(key: AppConstants.tokenExpiryKey);
    if (raw == null) {
      return null;
    }
    final expiry = DateTime.tryParse(raw);
    _cachedExpiry = expiry;
    return expiry;
  }

  Future<bool> hasValidLocalToken() async {
    final token = await readToken();
    final expiresAt = await readExpiry();
    if (token == null || token.isEmpty || expiresAt == null) {
      return false;
    }
    return expiresAt.isAfter(DateTime.now().toUtc());
  }

  Future<void> clearSession() async {
    _cachedToken = null;
    _cachedExpiry = null;
    await _storage.delete(key: AppConstants.tokenKey);
    await _storage.delete(key: AppConstants.tokenExpiryKey);
  }
}
