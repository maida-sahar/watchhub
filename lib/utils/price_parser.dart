/// Shared helper for turning a price [TextFormField]'s raw text into a
/// numeric value.
///
/// Root cause this exists to fix: the Regular/Discount price fields'
/// validators (and the code that reads them on submit) previously called
/// `double.tryParse(val)` directly on the field's raw text. `double.tryParse`
/// has no concept of currency symbols or thousands separators — it returns
/// `null` for anything that isn't a plain number, so a value like
/// `"$ 12,500"` (a `$ ` prefix and/or a `,` thousands separator, e.g. from
/// locale-aware numeric keyboards, pasted values, or pre-filled text) failed
/// to parse and the field showed "Must be >= 0" even though 12500 is a
/// perfectly valid, non-negative price.
///
/// [PriceParser.tryParse] strips everything except digits and a single
/// decimal point before parsing, so `"$ 12,500"`, `"12,500"`, `"$12500"`,
/// and `"12500"` all parse to the same `12500.0`. This is the single place
/// that does that sanitization — every price field validator and every
/// submit-time parse in the Product forms should go through this instead of
/// calling `double.tryParse`/`double.parse` directly, so the behavior stays
/// identical everywhere prices are read.
class PriceParser {
  const PriceParser._();

  /// Parses [input], stripping currency symbols, thousands separators, and
  /// surrounding whitespace first. Returns `null` if [input] is null, empty
  /// once cleaned, or not a valid number after cleaning (e.g. multiple
  /// decimal points).
  static double? tryParse(String? input) {
    if (input == null) return null;
    // Keep only digits and '.' — this deliberately also strips a leading
    // '-' since prices are never negative in this app; a genuinely
    // malformed value (e.g. "12.34.56") still correctly fails to parse.
    final cleaned = input.replaceAll(RegExp(r'[^0-9.]'), '');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }
}