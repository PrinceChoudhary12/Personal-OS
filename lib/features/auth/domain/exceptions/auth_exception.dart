// lib/features/auth/domain/exceptions/auth_exception.dart

/// Domain-level auth exception that wraps raw Firebase errors
/// into user-friendly messages.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;

  factory AuthException.fromCode(String code) {
    switch (code) {
      case 'email-already-in-use':
        return const AuthException(
          'An account already exists with this email address.',
        );
      case 'invalid-email':
        return const AuthException(
          'The email address is not valid.',
        );
      case 'user-not-found':
        return const AuthException(
          'No account found for this email. Please sign up.',
        );
      case 'wrong-password':
        return const AuthException(
          'Incorrect password. Please try again.',
        );
      case 'weak-password':
        return const AuthException(
          'Password is too weak. Use at least 6 characters.',
        );
      case 'too-many-requests':
        return const AuthException(
          'Too many attempts. Please wait a moment and try again.',
        );
      case 'network-request-failed':
        return const AuthException(
          'Network error. Check your internet connection.',
        );
      case 'user-disabled':
        return const AuthException(
          'This account has been disabled. Contact support.',
        );
      default:
        return AuthException(
          'Authentication failed: $code. Please try again.',
        );
    }
  }
}
