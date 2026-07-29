import 'dart:math';

/// Pembangkit ID unik sederhana tanpa dependency eksternal.
///
/// Menggabungkan timestamp mikrodetik dengan komponen acak agar cukup unik
/// untuk penyimpanan lokal. Bisa diganti uuid saat pindah ke database nyata.
class IdGenerator {
  IdGenerator._();

  static final Random _random = Random();

  static String generate() {
    final time = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    final rand = _random.nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0');
    return '$time-$rand';
  }
}
