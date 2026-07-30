import 'package:flutter/foundation.dart';

/// Ringkasan hasil backup: isi JSON siap ekspor + nama file yang disarankan.
///
/// Entitas domain — tidak tahu tentang File / SharedPreferences / share sheet.
@immutable
class BackupSnapshot {
  const BackupSnapshot({required this.json, required this.suggestedFileName});

  /// Konten JSON backup (biasanya di-*pretty print*).
  final String json;

  /// Nama file yang disarankan saat mengekspor (mis. dibagikan).
  final String suggestedFileName;
}
