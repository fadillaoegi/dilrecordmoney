import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data_backup_providers.dart';

/// Hasil menjalankan tugas backup otomatis saat app dibuka.
enum AutoBackupOutcome {
  /// Tidak ada yang perlu dilakukan (backup hari ini sudah pernah jalan).
  idle,

  /// Data lokal kosong & berhasil dipulihkan dari file backup otomatis.
  restored,

  /// Backup harian baru saja dibuat/ditimpa.
  backedUp,
}

/// Dijalankan sekali tiap app dibuka (dipicu dari Splash): pertama coba
/// pulihkan dari file backup otomatis bila data lokal kosong, baru setelah
/// itu jalankan backup harian bila belum dilakukan hari ini.
class AutoBackupNotifier extends AsyncNotifier<AutoBackupOutcome> {
  @override
  Future<AutoBackupOutcome> build() async {
    final repo = ref.read(backupRepositoryProvider);

    final restored = await repo.restoreFromAutoBackupIfEmpty();
    if (restored) {
      // Provider data belum diakses oleh Splash saat backup berjalan. Biarkan
      // provider tersebut memuat data terbaru dari SharedPreferences saat UI
      // berikutnya mulai me-watch-nya, alih-alih meng-invalidate provider saat
      // framework masih membangun ProviderScope.
      return AutoBackupOutcome.restored;
    }

    final backedUp = await repo.runDailyAutoBackupIfDue();
    return backedUp ? AutoBackupOutcome.backedUp : AutoBackupOutcome.idle;
  }
}

final autoBackupProvider =
    AsyncNotifierProvider<AutoBackupNotifier, AutoBackupOutcome>(
      AutoBackupNotifier.new,
    );
