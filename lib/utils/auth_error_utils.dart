String mapFirebaseAuthError(String code) {
  switch (code) {
    case 'user-not-found':
    case 'wrong-password':
      return 'Invalid email or password.';
    case 'invalid-email':
      return 'Invalid email format.';
    case 'email-already-in-use':
      return 'Email already in use.';
    case 'weak-password':
      return 'Password is too weak.';
    case 'too-many-requests':
      return 'Too many attempts. Try again later.';
    case 'invalid-action-code':
      return 'This sign-in link is invalid or has already been used.';
    case 'expired-action-code':
      return 'This sign-in link has expired. Please request a new one.';
    case 'invalid-credential':
      return 'This sign-in link could not be verified. Request a new link.';
    case 'invalid-continue-uri':
      return 'Reset link configuration error. Please contact support.';
    case 'unauthorized-domain':
    case 'unauthorized-continue-uri':
      return 'This domain is not authorized for password reset in Firebase.';
    case 'missing-continue-uri':
      return 'Reset link could not be generated. Please try again later.';
    default:
      return 'An error occurred. Please try again.';
  }
}