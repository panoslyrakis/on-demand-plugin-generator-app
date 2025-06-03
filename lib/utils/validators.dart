class Validators {
  // Prevent instantiation
  Validators._();
  
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
  
  static String? validateUsername(String? value) {
    return validateRequired(value, 'Username');
  }
  
  static String? validatePassword(String? value) {
    return validateRequired(value, 'App password');
  }
  
  static String? validatePluginTitle(String? value) {
    return validateRequired(value, 'Plugin title');
  }
  
  static String? validatePluginDescription(String? value) {
    return validateRequired(value, 'Plugin description');
  }
  
  static String? validateWorkingDirectory(String? value) {
    return validateRequired(value, 'Working directory');
  }
}