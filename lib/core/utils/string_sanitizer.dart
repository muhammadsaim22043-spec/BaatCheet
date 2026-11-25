// lib/core/utils/string_sanitizer.dart

class StringSanitizer {
  /// Cleans a string by trimming whitespace and removing potentially harmful
  /// HTML/Script tags to prevent XSS and UI breakage.
  static String sanitize(String? input, {int? maxLength}) {
    if (input == null) return '';

    // 1. Trim leading and trailing whitespace
    String clean = input.trim();

    // 2. Basic HTML tag removal (strips anything between < and >)
    // This prevents users from injecting <script> tags or HTML that might break the UI
    clean = clean.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), '');

    // 3. Length Limiting (Prevent database bloating or buffer attacks)
    if (maxLength != null && clean.length > maxLength) {
      clean = clean.substring(0, maxLength);
    }

    return clean;
  }

  /// Specialized sanitizer for phone numbers
  static String sanitizePhone(String input) {
    // Keep only numbers and the + sign
    return input.replaceAll(RegExp(r'[^\d+]'), '');
  }

  /// Specialized sanitizer for emails
  static String sanitizeEmail(String input) {
    // Lowcase and trim
    return input.trim().toLowerCase();
  }

  /// Validates Pakistani Phone Numbers
  /// Matches +923..., 923..., 03..., or 3... followed by 9 digits
  static bool isValidPakistaniPhone(String input) {
    final clean = sanitizePhone(input);
    return RegExp(r'^(\+92|92|0|)?3\d{9}$').hasMatch(clean);
  }

  /// Converts any accepted Pakistani format (03..., 3..., 92..., +92...) to
  /// E.164 (+923XXXXXXXXX). Firebase Phone Auth only accepts E.164, and storing
  /// one canonical format keeps the Firestore phone lookup consistent.
  /// Returns null if the number is not a valid Pakistani mobile number.
  static String? normalizePakistaniPhone(String input) {
    final clean = sanitizePhone(input);
    final match = RegExp(r'^(?:\+92|92|0)?(3\d{9})$').firstMatch(clean);
    if (match == null) return null;
    return '+92${match.group(1)}';
  }

  /// First letter of a name for avatars, safe for empty strings.
  static String initial(String name) {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
  }

  /// Validates Basic Email Format
  static bool isValidEmail(String input) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(input.trim());
  }
}
