/// Secure-storage keys for the Remember Me login preference.
class RememberMeStorage {
  RememberMeStorage._();

  static const enabledKey = 'remember_me_enabled';
  static const emailKey = 'remembered_email';

  static bool isEnabled(String? storedValue) => storedValue == 'true';
}