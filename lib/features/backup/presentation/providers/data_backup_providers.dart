import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/shared_preferences_provider.dart';
import '../../data/data_backup_service.dart';

final dataBackupServiceProvider = Provider<DataBackupService>((ref) {
  return DataBackupService(ref.watch(sharedPreferencesProvider));
});
