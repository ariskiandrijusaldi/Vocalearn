import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vocalearn/data/repositories/admin_service.dart';
import 'package:vocalearn/features/admin/admin_home_screen.dart';

class _FakeAdminService extends AdminService {
  final List<dynamic> courses;
  final List<dynamic> jurusan;
  _FakeAdminService(this.courses, this.jurusan) : super(dio: Dio());
  @override
  Future<List<dynamic>> getCourses() async => courses;
  @override
  Future<Map<String, dynamic>> getStats() async => {};
  @override
  Future<List<dynamic>> getJurusan() async => jurusan;
}

void main() {
  final courses = [
    {
      'id': 1,
      'code': 'BING101',
      'name': 'Bahasa Inggris Dasar',
      'prodi': 'S1 Teknik Informatika',
      'semester': 1,
      'credits': 3,
      'description': null,
    },
    {
      'id': 2,
      'code': 'BJEP102',
      'name': 'Bahasa Jepang Percakapan',
      'prodi': 'S1 Teknik Informatika',
      'semester': 2,
      'credits': 2,
      'description': null,
    },
    {
      'id': 3,
      'code': 'BMAN103',
      'name': 'Bahasa Mandarin Bisnis',
      'prodi': 'S1 Akuntansi',
      'semester': 3,
      'credits': 3,
      'description': null,
    },
    {
      'id': 4,
      'code': 'BJHI101',
      'name': 'Bahasa Jepang Pariwisata',
      'prodi': 'Manajemen Informatika',
      'semester': 4,
      'credits': 2,
      'description': null,
    },
  ];
  final jurusan = [
    {
      'id': 1,
      'name': 'Akuntansi',
      'prodi': [
        {'id': 4, 'name': 'S1 Akuntansi', 'jurusan_id': 1},
      ],
    },
    {
      'id': 2,
      'name': 'Teknologi Informasi',
      'prodi': [
        {'id': 1, 'name': 'S1 Teknik Informatika', 'jurusan_id': 2},
        {'id': 2, 'name': 'Manajemen Informatika', 'jurusan_id': 2},
      ],
    },
  ];

  testWidgets('Courses disusun Jurusan -> Prodi -> Semester -> mk',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        adminServiceProvider.overrideWithValue(_FakeAdminService(courses, jurusan)),
      ],
      child: const MaterialApp(home: AdminHomeScreen()),
    ));
    await tester.pump();
    await tester.tap(find.text('Mata Kuliah'));
    await tester.pumpAndSettle();

    // Level 1: hanya jurusan yang tampil, belum ada prodi/semester/MK.
    expect(find.text('Teknologi Informasi'), findsOneWidget);
    expect(find.text('Akuntansi'), findsOneWidget);
    expect(find.text('S1 Teknik Informatika'), findsNothing);
    expect(find.text('Bahasa Inggris Dasar'), findsNothing);

    // Klik jurusan -> muncul prodi di dalamnya.
    await tester.tap(find.text('Teknologi Informasi'));
    await tester.pumpAndSettle();
    expect(find.text('S1 Teknik Informatika'), findsOneWidget);
    expect(find.text('Manajemen Informatika'), findsOneWidget);
    expect(find.text('Semester 1'), findsNothing);
    expect(find.text('Bahasa Inggris Dasar'), findsNothing);

    // Klik prodi -> muncul semester.
    await tester.tap(find.text('S1 Teknik Informatika'));
    await tester.pumpAndSettle();
    expect(find.text('Semester 1'), findsOneWidget);
    expect(find.text('Semester 2'), findsOneWidget);
    expect(find.text('Bahasa Inggris Dasar'), findsNothing);

    // Klik semester -> barulah muncul mata kuliah.
    await tester.tap(find.text('Semester 1'));
    await tester.pumpAndSettle();
    expect(find.text('BING101 - Bahasa Inggris Dasar'), findsOneWidget);
    expect(find.text('BJEP102 - Bahasa Jepang Percakapan'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}