class StringCaseService {
  StringCaseService._();
  
  /// Normalize string to contain only alphanumeric, spaces, and underscores
  static String normalizeString(String input) {
    // Replace unauthorized characters with underscores
    String normalized = input.replaceAll(RegExp(r'[^a-zA-Z0-9\s_]+'), '_');
    
    // Clean up multiple consecutive underscores
    normalized = normalized.replaceAll(RegExp(r'_+'), '_');
    
    // Trim leading/trailing underscores and spaces
    normalized = normalized.trim().replaceAll(RegExp(r'^[_\s]+|[_\s]+$'), '');
    
    return normalized;
  }
  
  /// Convert to PascalCase
  static String toPascalCase(String input) {
    if (input.isEmpty) return input;
    
    // Split by spaces, underscores, and hyphens
    final words = input.split(RegExp(r'[\s_-]+'))
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .toList();
    
    return words.join('');
  }
  
  /// Convert to camelCase
  static String toCamelCase(String input) {
    final pascalCase = toPascalCase(input);
    if (pascalCase.isEmpty) return pascalCase;
    
    return pascalCase[0].toLowerCase() + pascalCase.substring(1);
  }
  
  /// Convert to snake_case
  static String toSnakeCase(String input) {
    if (input.isEmpty) return input;
    
    // Replace spaces and hyphens with underscores
    String result = input.replaceAll(RegExp(r'[\s-]+'), '_');
    
    // Add underscores before uppercase letters (except at start)
    result = result.replaceAllMapped(
      RegExp(r'([a-z0-9])([A-Z])'),
      (match) => '${match.group(1)}_${match.group(2)}',
    );
    
    return result.toLowerCase();
  }
  
  /// Convert to kebab-case
  static String toKebabCase(String input) {
    if (input.isEmpty) return input;
    
    // Replace spaces and underscores with hyphens
    String result = input.replaceAll(RegExp(r'[\s_]+'), '-');
    
    // Add hyphens before uppercase letters (except at start)
    result = result.replaceAllMapped(
      RegExp(r'([a-z0-9])([A-Z])'),
      (match) => '${match.group(1)}-${match.group(2)}',
    );
    
    return result.toLowerCase();
  }
  
  /// Convert to SCREAMING_SNAKE_CASE
  static String toScreamingSnakeCase(String input) {
    return toSnakeCase(input).toUpperCase();
  }
  
  /// Convert to flatcase (all lowercase, no separators)
  static String toFlatCase(String input) {
    return input.replaceAll(RegExp(r'[\s_-]+'), '').toLowerCase();
  }
  
  /// Convert to Pascal_Snake_Case
  static String toPascalSnakeCase(String input) {
    if (input.isEmpty) return input;
    
    final words = input.split(RegExp(r'[\s_-]+'))
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .toList();
    
    return words.join('_');
  }
  
  /// Capitalize first letter only
  static String capitalizeFirst(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1);
  }
  
  /// Get all case variations of a string
  static Map<String, String> getAllCaseVariations(String input) {
    return {
      'original': input,
      'normalized': normalizeString(input),
      'camelCase': toCamelCase(input),
      'PascalCase': toPascalCase(input),
      'snake_case': toSnakeCase(input),
      'kebab-case': toKebabCase(input),
      'SCREAMING_SNAKE_CASE': toScreamingSnakeCase(input),
      'flatcase': toFlatCase(input),
      'Pascal_Snake_Case': toPascalSnakeCase(input),
      'Capitalize First': capitalizeFirst(input),
    };
  }
}