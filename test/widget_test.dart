// Smoke test dasar: memastikan splash tampil saat aplikasi dijalankan.

import 'package:dilrecordmoney/core/providers/shared_preferences_provider.dart';
import 'package:dilrecordmoney/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Menampilkan splash saat aplikasi dimulai', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const DilRecordApp(),
      ),
    );

    // Frame pertama menampilkan nama aplikasi pada splash.
    await tester.pump();
    expect(find.text('DilRecord Money'), findsOneWidget);

    // Lewati timer splash agar tidak ada timer tertunda saat teardown,
    // lalu berpindah ke onboarding (prefs kosong = belum pernah lihat).
    await tester.pump(const Duration(seconds: 3)); // timer splash selesai → go()
    await tester.pump(); // mulai transisi rute
    await tester.pump(const Duration(milliseconds: 500)); // selesaikan fade
    expect(find.text('Catat Setiap Rupiah'), findsOneWidget);
  });
}
