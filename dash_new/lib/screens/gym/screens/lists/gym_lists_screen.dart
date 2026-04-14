import 'package:flutter/material.dart';
import 'package:focuslane/screens/gym/services/gym_firestore_service.dart';
import 'package:focuslane/screens/gym/screens/analytics/gym_analytics_screen.dart';

class GymListsScreen extends StatelessWidget {
  final GymFirestoreService svc;

  const GymListsScreen({super.key, required this.svc});

  @override
  Widget build(BuildContext context) {
    return GymAnalyticsScreen(svc: svc);
  }
}


