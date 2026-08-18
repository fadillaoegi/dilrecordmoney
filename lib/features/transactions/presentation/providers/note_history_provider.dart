import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'transaction_providers.dart';

/// Riwayat catatan unik yang pernah dipakai di transaksi mana pun.
///
/// Diturunkan dari [transactionListProvider] — jadi selalu tersinkron tanpa
/// perlu penyimpanan terpisah. Diurutkan **paling baru dulu** (berdasarkan
/// tanggal transaksi terakhir yang memakai catatan itu) sehingga sugesti
/// terasa relevan dengan kebiasaan pengguna belakangan ini.
final noteHistoryProvider = Provider<List<String>>((ref) {
  final transactions =
      ref.watch(transactionListProvider).asData?.value ?? const [];

  // Simpan tanggal termuda per catatan (case-insensitive dedup, tapi tampilkan
  // versi tertulis asli agar kapitalisasi user tetap dipertahankan).
  final byKey = <String, ({String display, DateTime date})>{};
  for (final t in transactions) {
    final raw = t.note?.trim();
    if (raw == null || raw.isEmpty) continue;
    final key = raw.toLowerCase();
    final current = byKey[key];
    if (current == null || t.date.isAfter(current.date)) {
      byKey[key] = (display: raw, date: t.date);
    }
  }

  final entries = byKey.values.toList()
    ..sort((a, b) => b.date.compareTo(a.date));
  return entries.map((e) => e.display).toList();
});

/// Mencari sugesti catatan yang cocok dengan [query].
///
/// - Bila [query] kosong → kembalikan seluruh riwayat (maks. 6 teratas).
/// - Bila [query] terisi → filter yang mengandung [query] (case-insensitive),
///   kecualikan yang sama persis (tak berguna menyarankan apa yang sudah diketik).
List<String> filterNoteSuggestions(List<String> history, String query) {
  final trimmed = query.trim();
  if (trimmed.isEmpty) return history.take(6).toList();

  final lower = trimmed.toLowerCase();
  return history
      .where((n) => n.toLowerCase().contains(lower) && n.toLowerCase() != lower)
      .take(6)
      .toList();
}
