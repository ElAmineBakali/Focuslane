import 'package:flutter/material.dart';
import 'package:focuslane/screens/gym/services/gym_firestore_service.dart';
import 'package:focuslane/screens/gym/screens/session/session_history_screen.dart';

class GymHistoryScreen extends StatelessWidget {
  final GymFirestoreService svc;

  const GymHistoryScreen({super.key, required this.svc});

  @override
  Widget build(BuildContext context) {
    return SessionHistoryScreen(svc: svc);
  }
}


