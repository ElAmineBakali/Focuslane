import 'package:flutter/material.dart';
import '../../gym/services/gym_firestore_service.dart';
import '../../gym/analytics/gym_analytics_screen.dart';

class GymListsScreen extends StatelessWidget {
  final GymFirestoreService svc;

  const GymListsScreen({super.key, required this.svc});

  @override
  Widget build(BuildContext context) {
    return GymAnalyticsScreen(svc: svc);
  }
}
