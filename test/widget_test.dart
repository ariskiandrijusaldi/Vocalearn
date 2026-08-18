import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vocalearn/data/repositories/admin_repository_impl.dart';
import 'package:vocalearn/data/repositories/recommendation_repository_impl.dart';
import 'package:vocalearn/features/admin/presentation/screens/admin_home_screen.dart';

void main() {
  testWidgets('Admin home renders tabs and students', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AdminHomeScreen(
          adminRepository: AdminRepositoryImpl(),
          recommendationRepository: RecommendationRepositoryImpl(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('VocaLearn Super Admin'), findsOneWidget);
    expect(find.text('Mahasiswa'), findsWidgets);
    expect(find.text('Dosen'), findsWidgets);
    expect(find.text('Rina Kartika'), findsOneWidget);
  });
}
