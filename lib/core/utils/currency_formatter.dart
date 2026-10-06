import 'package:flutter/services.dart';

import '../l10n/app_strings.dart';

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

  /// Bentuk ringkas untuk sumbu grafik: `1250000` → `"1,3jt"`,
  /// `850000` → `"850rb"`. Satuan ikut bahasa aktif.
  static String compact(int amount) {
    final value = amount.abs();
    final sign = amount < 0 ? '-' : '';
    final t = AppStrings.t;
    String fmt(double v, String unit) {
      final text = v >= 10 || v == v.roundToDouble()
          ? v.round().toString()
          : v.toStringAsFixed(1).replaceAll('.', ',');
      return '$sign$text$unit';
    }

    if (value >= 1000000000) return fmt(value / 1000000000, t.unitB);
    if (value >= 1000000) return fmt(value / 1000000, t.unitM);
    if (value >= 1000) return fmt(value / 1000, t.unitK);
    return '$sign$value';
  }

  /// Versi tersamar untuk mode privasi (mis. `1000000` → `"Rp•••••••"`).
  ///
  /// Jumlah '•' mengikuti jumlah digit nominal asli agar tetap terasa
  /// proporsional, tanpa membocorkan nominalnya.
  static String obscure(int amount, {bool withSymbol = true}) {
    final symbol = withSymbol ? 'Rp' : '';
    return '$symbol${'•' * amount.abs().toString().length}';
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

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final intValue = int.tryParse(
      newValue.text.replaceAll(RegExp(r'[^0-9]'), ''),
    );
    if (intValue == null) {
      return oldValue;
    }

    final newString = CurrencyFormatter.rupiah(
      intValue,
      withSymbol: false,
      withSign: false,
    );

    return TextEditingValue(
      text: newString,
      selection: TextSelection.collapsed(offset: newString.length),
    );
  }
}
