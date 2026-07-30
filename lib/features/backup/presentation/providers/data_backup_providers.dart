import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/shared_preferences_provider.dart';
import '../../data/datasources/backup_local_datasource.dart';
import '../../data/repositories/backup_repository_impl.dart';
import '../../domain/repositories/backup_repository.dart';

// ── Dependency wiring (data → domain) ────────────────────────────────────────

final backupLocalDataSourceProvider = Provider<BackupLocalDataSource>((ref) {
  return BackupLocalDataSourceImpl(ref.watch(sharedPreferencesProvider));
});

/// Provider utama yang dipakai UI: mengembalikan **kontrak** [BackupRepository],
/// bukan implementasi konkret.
final backupRepositoryProvider = Provider<BackupRepository>((ref) {
  return BackupRepositoryImpl(ref.watch(backupLocalDataSourceProvider));
});
