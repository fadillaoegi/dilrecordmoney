import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/export_repository_impl.dart';
import '../../domain/repositories/export_repository.dart';

/// Provider utama yang dipakai UI: mengembalikan kontrak [ExportRepository].
final exportRepositoryProvider = Provider<ExportRepository>((ref) {
  return const ExportRepositoryImpl();
});
