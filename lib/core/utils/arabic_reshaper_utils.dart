import 'package:arabic_reshaper/arabic_reshaper.dart';

/// Utility class for reshaping Arabic AND Kurdish (Sorani) text for PDF generation.
///
/// The generic `arabic_reshaper` package only handles standard Arabic characters.
/// Kurdish (Sorani) uses additional glyphs not in its letter map:
///   - ێ (U+06CE) Ye with small V
///   - ڵ (U+06B5) Lam with small V
///   - ڕ (U+0695) Re with small V
///   - ە (U+06D5) AE
///
/// This utility handles two cases:
/// 1. For text with NO Kurdish-specific chars: delegates to standard reshaper.
/// 2. For text WITH Kurdish chars: reshapes Arabic portions normally and passes
///    Kurdish-only chars through as raw codepoints, relying on NotoNaskhArabic
///    font's OpenType GSUB/GPOS tables to apply contextual shaping at the PDF
///    rendering level (the pdf package v3.11+ triggers OT shaping via HarfBuzz).
class ArabicReshaperUtils {
  ArabicReshaperUtils._();

  /// Kurdish-only characters NOT in the arabic_reshaper LETTERS_ARABIC map.
  static const Set<String> _kurdishOnly = {
    '\u06CE', // ێ Ye with small V above
    '\u06B5', // ڵ Lam with small V above
    '\u0695', // ڕ Re with small V below
    '\u06D5', // ە AE
  };

  /// Reshapes the given [text] for proper rendering in PDFs.
  /// Handles both standard Arabic and Sorani Kurdish correctly.
  static String reshape(String text) {
    if (text.isEmpty) return text;
    if (!ArabicReshaper.isArabic(text)) return text;

    // Fast path: if no Kurdish-only chars, use standard reshaper directly
    bool hasKurdish = false;
    for (final c in text.characters) {
      if (_kurdishOnly.contains(c)) {
        hasKurdish = true;
        break;
      }
    }

    if (!hasKurdish) {
      return ArabicReshaper.instance.reshape(text);
    }

    return _reshapeMixed(text);
  }

  static String _reshapeMixed(String text) {
    final buffer = StringBuffer();
    final chars = text.characters.toList();
    int i = 0;

    while (i < chars.length) {
      final String ch = chars[i];

      if (!ArabicReshaper.isArabic(ch)) {
        buffer.write(ch);
        i++;
        continue;
      }

      // Collect a contiguous RTL run
      final int start = i;
      while (i < chars.length && ArabicReshaper.isArabic(chars[i])) {
        i++;
      }

      final List<String> run = chars.sublist(start, i);
      buffer.write(_shapeRun(run));
    }

    return buffer.toString();
  }

  static String _shapeRun(List<String> chars) {
    if (chars.isEmpty) return '';

    // Split the run at Kurdish-only characters.
    // Arabic sub-segments → standard reshaper.
    // Kurdish chars → pass through raw for font-level OT shaping.
    final output = StringBuffer();
    int i = 0;

    while (i < chars.length) {
      final String ch = chars[i];

      if (_kurdishOnly.contains(ch)) {
        // Kurdish char: pass through as raw codepoint.
        // NotoNaskhArabic + PDF engine's OT shaping handles contextual forms.
        output.write(ch);
        i++;
      } else {
        // Collect a sub-run of non-Kurdish Arabic chars
        final int start = i;
        while (i < chars.length && !_kurdishOnly.contains(chars[i])) {
          i++;
        }
        final String subRun = chars.sublist(start, i).join();
        if (subRun.isNotEmpty && ArabicReshaper.isArabic(subRun)) {
          output.write(ArabicReshaper.instance.reshape(subRun));
        } else {
          output.write(subRun);
        }
      }
    }

    return output.toString();
  }
}
