import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vocalearn/data/repositories/admin_service.dart';
import 'package:vocalearn/features/admin/admin_home_screen.dart';

class _FakeAdminService extends AdminService {
  final Map<String, dynamic> stats;
  _FakeAdminService(this.stats) : super(dio: Dio());
  @override
  Future<Map<String, dynamic>> getStats() async => stats;
}

Widget _harness(Map<String, dynamic> stats) {
  return ProviderScope(
    overrides: [
      adminServiceProvider.overrideWithValue(_FakeAdminService(stats)),
    ],
    child: const MaterialApp(home: AdminHomeScreen()),
  );
}

Future<void> _openMonitoring(WidgetTester tester, Map<String, dynamic> stats) async {
  await tester.pumpWidget(_harness(stats));
  await tester.pump();
  await tester.tap(find.text('Monitoring'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Monitoring renders with live payload (all zeros)', (tester) async {
    await _openMonitoring(tester, {
      'total_users': 12,
      'users_by_role': [
        {'role': 'super_admin', 'count': 1},
        {'role': 'dosen', 'count': 4},
        {'role': 'mahasiswa', 'count': 7},
      ],
      'total_courses': 14,
      'total_modules': 0,
      'modules_by_status': <dynamic>[],
      'total_interactions': 0,
      'avg_score': 0.0,
      'daily_activity': <dynamic>[],
      'jurusan_stats': <dynamic>[],
    });

    expect(find.text('Monitoring Sistem'), findsOneWidget);
    expect(find.text('Belum ada data modul.'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(find.text('Belum ada data jurusan.'), 400);
    await tester.scrollUntilVisible(find.text('Belum ada data modul.'), 400);
    await tester.scrollUntilVisible(find.text('Belum ada data aktivitas.'), 400);
    await tester.pumpAndSettle();
    expect(find.text('Belum ada data jurusan.'), findsOneWidget);
    expect(find.text('Belum ada data modul.'), findsOneWidget);
    expect(find.text('Belum ada data aktivitas.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Monitoring renders charts with populated payload', (tester) async {
    await _openMonitoring(tester, {
      'total_users': 12,
      'users_by_role': [
        {'role': 'super_admin', 'count': 1},
        {'role': 'dosen', 'count': 4},
        {'role': 'mahasiswa', 'count': 7},
      ],
      'total_courses': 14,
      'total_modules': 8,
      'modules_by_status': [
        {'status': 'published', 'count': 5},
        {'status': 'draft', 'count': 3},
      ],
      'total_interactions': 120,
      'avg_score': 78.5,
      'daily_activity': [
        for (var i = 1; i <= 14; i++)
          {
            'date': '2026-08-${i.toString().padLeft(2, '0')}',
            'interactions': i * 5,
            'avg_score': 70.0 + i,
          },
      ],
      'jurusan_stats': [
        {
          'id': 1,
          'name': 'Teknologi Informasi',
          'total_prodi': 3,
          'total_students': 7,
          'total_courses': 4,
          'total_modules': 2,
          'total_interactions': 80,
          'avg_score': 79.0,
        },
      ],
    });

    expect(find.text('Monitoring Sistem'), findsOneWidget);
    expect(find.text('120'), findsOneWidget);
    expect(find.text('78.5'), findsOneWidget);
    expect(find.text('Teknologi Informasi'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(find.text('Monitoring Jurusan'), 300);
    await tester.pumpAndSettle();
    expect(find.text('Monitoring Jurusan'), findsOneWidget);
    expect(find.text('Teknologi Informasi'), findsOneWidget);
    expect(find.text('3 prodi'), findsOneWidget);
    expect(find.text('79.0'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(find.text('Jumlah Interaksi'), 400);
    await tester.pumpAndSettle();
    expect(find.text('Jumlah Interaksi'), findsOneWidget);
    expect(find.text('published'), findsOneWidget);
    expect(find.text('draft'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}