/// Utilitas format mata uang Rupiah tanpa dependency eksternal.
///
/// Nominal disimpan sebagai [int] Rupiah utuh (tanpa sen) untuk menghindari
/// galat pembulatan floating point.
class CurrencyFormatter {
  CurrencyFormatter._();

  /// Contoh: `1000000` → `"Rp1.000.000"`.
  static String rupiah(
    int amount, {
    bool withSymbol = true,
    bool withSign = false,
  }) {
    final negative = amount < 0;
    final grouped = _group(amount.abs());
    final sign = negative
        ? '-'
        : withSign
        ? '+'
        : '';
    final symbol = withSymbol ? 'Rp' : '';
    return '$sign$symbol$grouped';
  }

  /// Menyisipkan pemisah ribuan '.' ala Indonesia.
  static String _group(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}
