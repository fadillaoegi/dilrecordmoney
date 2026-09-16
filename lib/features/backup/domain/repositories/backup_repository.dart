import 'dart:io';

import '../entities/backup_snapshot.dart';

/// Kontrak fitur backup/restore.
///
/// Layer domain hanya mendefinisikan operasi tingkat bisnis. Detail teknis
/// (SharedPreferences, path_provider, format JSON) berada di layer data.
abstract interface class BackupRepository {
  /// Membuat snapshot backup dari state aplikasi saat ini.
  BackupSnapshot createSnapshot();

  /// Menuliskan [snapshot] ke berkas sementara sehingga siap dibagikan.
  Future<File> writeSnapshotToFile(BackupSnapshot snapshot);

  /// Memulihkan seluruh state aplikasi dari konten backup [rawJson].
  ///
  /// Wajib memvalidasi identitas & versi skema. Lempar `BackupFailure` bila
  /// konten tidak valid.
  Future<void> restoreFromJson(String rawJson);

  /// Bila belum ada transaksi sama sekali (mis. baru install) dan ada file
  /// backup otomatis tersimpan, pulihkan otomatis dari situ.
  ///
  /// Mengembalikan `true` bila benar-benar memulihkan sesuatu.
  Future<bool> restoreFromAutoBackupIfEmpty();

  /// Menjalankan backup otomatis harian bila belum dilakukan hari ini —
  /// menimpa file backup otomatis sebelumnya (bukan menumpuk file baru).
  ///
  /// Mengembalikan `true` bila backup baru benar-benar dibuat hari ini.
  Future<bool> runDailyAutoBackupIfDue({DateTime? now});
}
