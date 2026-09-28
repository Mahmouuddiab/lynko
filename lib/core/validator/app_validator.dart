class AppValidator {
  /// Basic required field check
  static String? required(
      String? value, {
        String message = 'required_field',
      }) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }
    return null;
  }

  /// Full name validation
  static String? name(String? value, {String? requiredMsg, String? invalidMsg}) {
    final requiredError = required(value, message: requiredMsg ?? 'Enter Name Please');
    if (requiredError != null) return requiredError;

    if (value!.trim().length < 3) {
      return invalidMsg ?? 'name_too_short';
    }

    return null;
  }

  /// Email validation
  static String? email(String? value, {String? requiredMsg, String? invalidMsg}) {
    final requiredError = required(value, message: requiredMsg ?? 'Enter Email Please');
    if (requiredError != null) return requiredError;

    final emailRegex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[a-zA-Z]{2,}$');

    return emailRegex.hasMatch(value!.trim())
        ? null
        : (invalidMsg ?? 'invalid_email');
  }

  /// Password validation
  static String? password(String? value, {String? requiredMsg, String? invalidMsg}) {
    final requiredError = required(value, message: requiredMsg ?? 'Enter Password');
    if (requiredError != null) return requiredError;

    if (value!.length < 8) {
      return invalidMsg ?? 'password_too_short';
    }

    return null;
  }
}