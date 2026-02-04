import 'package:flutter/material.dart';
import '../../gym/services/gym_firestore_service.dart';
import '../../gym/routines/preset_routines_screen.dart';

class GymPlannerScreen extends StatelessWidget {
  final GymFirestoreService svc;

  const GymPlannerScreen({super.key, required this.svc});

  @override
  Widget build(BuildContext context) {
    return PresetRoutinesScreen(svc: svc);
  }
}
