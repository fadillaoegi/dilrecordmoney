/// Kegagalan yang bermakna secara domain untuk fitur backup/restore.
///
/// UI hanya perlu menangkap tipe ini — layer data mengubah semua pengecualian
/// tingkat rendah (I/O, JSON, dsb.) menjadi [BackupFailure] dengan pesan
/// yang bisa dibaca pengguna.
class BackupFailure implements Exception {
  const BackupFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
