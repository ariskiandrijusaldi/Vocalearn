import 'package:flutter/material.dart';

import 'data/repositories/admin_api_repository.dart';
import 'data/repositories/recommendation_api_repository.dart';
import 'features/admin/presentation/screens/admin_home_screen.dart';

void main() {
  runApp(const VocalearnApp());
}

class VocalearnApp extends StatelessWidget {
  const VocalearnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VocaLearn Adaptive Learnig',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: AdminHomeScreen(
        adminRepository: AdminApiRepository(),
        recommendationRepository: RecommendationApiRepository(),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
