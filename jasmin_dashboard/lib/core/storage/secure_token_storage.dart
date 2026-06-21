import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';

final secureTokenStorageProvider = Provider<SecureTokenStorage>((ref) {
  return const SecureTokenStorage();
});

class SecureTokenStorage {
  const SecureTokenStorage();

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
    await _storage.write(key: AppConstants.tokenKey, value: token);
    await _storage.write(
      key: AppConstants.tokenExpiryKey,
      value: expiresAt.toIso8601String(),
    );
  }

  Future<String?> readToken() => _storage.read(key: AppConstants.tokenKey);

  Future<DateTime?> readExpiry() async {
    final raw = await _storage.read(key: AppConstants.tokenExpiryKey);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<bool> hasValidLocalToken() async {
    final token = await readToken();
    final expiresAt = await readExpiry();
    if (token == null || token.isEmpty || expiresAt == null) return false;
    return expiresAt.isAfter(DateTime.now().toUtc());
  }

  Future<void> clearSession() async {
    await _storage.delete(key: AppConstants.tokenKey);
    await _storage.delete(key: AppConstants.tokenExpiryKey);
  }
}
