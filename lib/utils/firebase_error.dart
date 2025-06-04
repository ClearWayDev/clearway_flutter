import 'package:firebase_auth/firebase_auth.dart';

String getFirebaseAuthErrorMessage(FirebaseAuthException e) {
  switch (e.code) {
    // Common sign-in errors
    case 'invalid-email':
    case 'ERROR_INVALID_EMAIL':
      return 'The email address format is invalid. Please check and try again.';
    case 'wrong-password':
    case 'ERROR_WRONG_PASSWORD':
      return 'The password is incorrect. Please try again.';
    case 'user-not-found':
    case 'ERROR_USER_NOT_FOUND':
      return 'No account found with this email.';
    case 'user-disabled':
    case 'ERROR_USER_DISABLED':
      return 'This user account has been disabled. Contact support for help.';
    case 'too-many-requests':
    case 'ERROR_TOO_MANY_REQUESTS':
      return 'Too many login attempts. Please wait a moment and try again.';
    case 'operation-not-allowed':
    case 'ERROR_OPERATION_NOT_ALLOWED':
      return 'Email and password sign-in is currently not enabled.';

    // Sign-up specific
    case 'email-already-in-use':
    case 'ERROR_EMAIL_ALREADY_IN_USE':
      return 'An account already exists with this email address.';
    case 'weak-password':
    case 'ERROR_WEAK_PASSWORD':
      return 'Password must be at least 6 characters long.';

    // Credential-related
    case 'invalid-credential':
    case 'ERROR_INVALID_CREDENTIAL':
      return 'The provided credential is invalid or expired.';
    case 'account-exists-with-different-credential':
    case 'ERROR_ACCOUNT_EXISTS_WITH_DIFFERENT_CREDENTIAL':
      return 'An account already exists with the same email address but different sign-in credentials.';

    // Custom token errors
    case 'invalid-custom-token':
    case 'ERROR_INVALID_CUSTOM_TOKEN':
      return 'The custom token format is incorrect.';
    case 'custom-token-mismatch':
    case 'ERROR_CUSTOM_TOKEN_MISMATCH':
      return 'Custom token mismatch. Check your Firebase project configuration.';

    // Password reset & verification
    case 'expired-action-code':
    case 'EXPIRED_ACTION_CODE':
      return 'The reset link has expired. Please request a new one.';
    case 'invalid-action-code':
    case 'INVALID_ACTION_CODE':
      return 'The reset link is invalid or has already been used.';
    case 'invalid-verification-code':
    case 'ERROR_INVALID_VERIFICATION_CODE':
      return 'The verification code is invalid or expired.';

    default:
      return 'An unexpected error occurred. Please try again later.';
  }
}
