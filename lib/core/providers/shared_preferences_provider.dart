import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider untuk instance [SharedPreferences].
///
/// Di-*override* di `main.dart` dengan instance yang sudah di-*await*
/// sehingga bisa diakses secara sinkron di seluruh aplikasi.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider harus di-override di main.dart');
});
