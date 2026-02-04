import 'package:flutter/material.dart';
import '../../study/services/study_firestore_service.dart';
import '../../study/schedule/schedule_screen.dart';

class StudyPlannerScreen extends StatelessWidget {
  final StudyFirestoreService svc;

  const StudyPlannerScreen({super.key, required this.svc});

  @override
  Widget build(BuildContext context) {
    return ScheduleScreen(svc: svc);
  }
}
