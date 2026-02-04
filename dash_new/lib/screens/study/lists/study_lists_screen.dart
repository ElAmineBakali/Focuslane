import 'package:flutter/material.dart';
import '../../study/services/study_firestore_service.dart';
import '../../study/tasks/study_tasks_screen.dart';

class StudyListsScreen extends StatelessWidget {
  final StudyFirestoreService svc;

  const StudyListsScreen({super.key, required this.svc});

  @override
  Widget build(BuildContext context) {
    return StudyTasksScreen(svc: svc);
  }
}
