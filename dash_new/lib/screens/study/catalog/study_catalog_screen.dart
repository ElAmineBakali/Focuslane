import 'package:flutter/material.dart';
import '../../study/services/study_firestore_service.dart';
import '../../study/courses/courses_list_screen.dart';

class StudyCatalogScreen extends StatelessWidget {
  final StudyFirestoreService svc;

  const StudyCatalogScreen({super.key, required this.svc});

  @override
  Widget build(BuildContext context) {
    return CoursesListScreen(svc: svc);
  }
}
