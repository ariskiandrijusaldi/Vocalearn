import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/competency.dart';

class CompetencyController extends StateNotifier<List<Competency>> {
  CompetencyController() : super([]);

  void setFromDiagnostic(List<Competency> results) {
    state = results;
  }
  static CompetencyStatus statusFromScore(double score) {
    if (score < 0.4) return CompetencyStatus.perluIntervensi;
    if (score <= 0.7) return CompetencyStatus.dalamProses;
    return CompetencyStatus.dikuasai;
  }
}

final competencyProvider =
StateNotifierProvider<CompetencyController, List<Competency>>(
      (ref) => CompetencyController(),
);
