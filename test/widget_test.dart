// Smoke test dasar untuk VocaLearn.
// Tes ini hanya memastikan app bisa dijalankan dan halaman Login muncul
// pertama kali (karena belum ada user yang login).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocalearn/main.dart';

void main() {
  testWidgets('VocaLearn menampilkan halaman Login saat belum login',
          (WidgetTester tester) async {
        // Bungkus dengan ProviderScope karena app pakai Riverpod.
        await tester.pumpWidget(const ProviderScope(child: VocaLearnApp()));
        await tester.pumpAndSettle();

        // Verifikasi elemen di LoginScreen muncul.
        expect(find.text('VocaLearn'), findsWidgets);
        expect(find.widgetWithText(FilledButton, 'Masuk'), findsOneWidget);
      });
}