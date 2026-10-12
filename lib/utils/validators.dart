/// Pure, stateless validation helpers for the authentication forms.
/// Each method returns `null` when valid, or a user-friendly error
/// message when invalid — ready to plug straight into a
/// `TextFormField`'s `validator:` callback.
class Validators {
  Validators._();

  static final RegExp _emailRegex =
      RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,}$');

  // Accepts optional leading + and 7-15 digits (E.164-ish, permissive).
  static final RegExp _phoneRegex = RegExp(r'^\+?[0-9]{7,15}$');

  static final RegExp _hasUppercase = RegExp(r'[A-Z]');
  static final RegExp _hasLowercase = RegExp(r'[a-z]');
  static final RegExp _hasDigit = RegExp(r'[0-9]');
  static final RegExp _hasSpecialChar = RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-\[\]/\\+=~`]');

  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required.';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters.';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required.';
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required.';
    }
    if (!_phoneRegex.hasMatch(value.trim())) {
      return 'Enter a valid phone number.';
    }
    return null;
  }

  /// Enforces: min 8 chars, at least one uppercase, one lowercase,
  /// one digit, and one special character.
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required.';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters.';
    }
    if (!_hasUppercase.hasMatch(value)) {
      return 'Password must contain at least one uppercase letter.';
    }
    if (!_hasLowercase.hasMatch(value)) {
      return 'Password must contain at least one lowercase letter.';
    }
    if (!_hasDigit.hasMatch(value)) {
      return 'Password must contain at least one number.';
    }
    if (!_hasSpecialChar.hasMatch(value)) {
      return 'Password must contain at least one special character.';
    }
    return null;
  }

  static String? validateConfirmPassword(String? password, String? confirm) {
    if (confirm == null || confirm.isEmpty) {
      return 'Please confirm your password.';
    }
    if (confirm != password) {
      return 'Passwords do not match.';
    }
    return null;
  }
}