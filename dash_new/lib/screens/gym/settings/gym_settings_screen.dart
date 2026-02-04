import 'package:flutter/material.dart';
import '../../gym/services/gym_firestore_service.dart';
import '../../gym/goals/gym_goals_screen.dart';

class GymSettingsScreen extends StatelessWidget {
  final GymFirestoreService svc;

  const GymSettingsScreen({super.key, required this.svc});

  @override
  Widget build(BuildContext context) {
    return GymGoalsScreen(svc: svc);
  }
}
