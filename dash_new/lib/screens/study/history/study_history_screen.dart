import 'package:flutter/material.dart';
import '../../study/services/study_firestore_service.dart';
import '../../study/analytics/study_analytics_screen.dart';

class StudyHistoryScreen extends StatelessWidget {
  final StudyFirestoreService svc;

  const StudyHistoryScreen({super.key, required this.svc});

  @override
  Widget build(BuildContext context) {
    return StudyAnalyticsScreen(svc: svc);
  }
}
