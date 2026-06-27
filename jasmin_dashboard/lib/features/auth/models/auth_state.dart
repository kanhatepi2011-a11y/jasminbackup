import 'admin_user.dart';

class AuthState {
  const AuthState({
    required this.status,
    this.admin,
    this.challengeId,
    this.challengeExpiresAt,
    this.loginEmail,
    this.errorMessage,
    this.infoMessage,
    this.isLoading = false,
  });

  factory AuthState.checking() => const AuthState(status: AuthStatus.checking);
  factory AuthState.unauthenticated(
      {String? errorMessage, String? infoMessage}) {
    return AuthState(
      status: AuthStatus.unauthenticated,
      errorMessage: errorMessage,
      infoMessage: infoMessage,
    );
  }

  final AuthStatus status;
  final AdminUser? admin;
  final String? challengeId;
  final DateTime? challengeExpiresAt;
  final String? loginEmail;
  final String? errorMessage;
  final String? infoMessage;
  final bool isLoading;

  bool get hasValidChallenge {
    final id = challengeId;
    final expiresAt = challengeExpiresAt;
    if (id == null || id.isEmpty || expiresAt == null) {
      return false;
    }
    return expiresAt.isAfter(DateTime.now().toUtc());
  }

  AuthState copyWith({
    AuthStatus? status,
    AdminUser? admin,
    String? challengeId,
    DateTime? challengeExpiresAt,
    String? loginEmail,
    String? errorMessage,
    String? infoMessage,
    bool? isLoading,
    bool clearAdmin = false,
    bool clearChallenge = false,
    bool clearError = false,
    bool clearInfo = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      admin: clearAdmin ? null : admin ?? this.admin,
      challengeId: clearChallenge ? null : challengeId ?? this.challengeId,
      challengeExpiresAt:
          clearChallenge ? null : challengeExpiresAt ?? this.challengeExpiresAt,
      loginEmail: clearChallenge ? null : loginEmail ?? this.loginEmail,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      infoMessage: clearInfo ? null : infoMessage ?? this.infoMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

enum AuthStatus {
  checking,
  unauthenticated,
  awaitingTwoFactor,
  authenticated,
}
