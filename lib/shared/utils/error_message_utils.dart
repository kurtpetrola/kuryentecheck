class ErrorMessageUtils {
  static String map(Object error) {
    if (error.toString().startsWith('AppException')) {}

    final s = error.toString();

    if (s.contains('user-not-found')) {
      return 'No user found with this email.';
    }
    if (s.contains('wrong-password')) {
      return 'Incorrect password.';
    }
    if (s.contains('email-already-in-use')) {
      return 'This email is already registered.';
    }
    if (s.contains('weak-password')) {
      return 'Password is too weak.';
    }
    if (s.contains('network-request-failed')) {
      return 'Network error. Please check your connection.';
    }

    // Fallback
    return 'An unexpected error occurred. Please try again.';
  }
}
