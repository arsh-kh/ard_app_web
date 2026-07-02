import 'package:arabic_reshaper/arabic_reshaper.dart';

/// Utility class for reshaping Arabic text.
/// This ensures proper rendering of Arabic script in environments that don't
/// support it natively (e.g., PDF generation).
class ArabicReshaperUtils {
  ArabicReshaperUtils._(); // Prevent instantiation

  /// Reshapes the given [text] if it contains Arabic characters.
  /// Otherwise, it returns the original [text] unchanged.
  static String reshape(String text) {
    // Check if the text contains any Arabic characters
    if (ArabicReshaper.isArabic(text)) {
      return ArabicReshaper.instance.reshape(text);
    }
    return text;
  }
}
