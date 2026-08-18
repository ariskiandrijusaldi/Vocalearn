import '../entities/recommendation.dart';
import '../entities/user.dart';

abstract class RecommendationRepository {
  Future<List<User>> getStudents();

  Future<Recommendation> getRecommendation(int studentId);

  Future<void> refresh();
}
