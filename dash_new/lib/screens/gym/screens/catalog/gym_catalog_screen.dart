import 'package:flutter/material.dart';
import 'package:focuslane/screens/gym/services/gym_firestore_service.dart';
import 'package:focuslane/screens/gym/screens/routines/routines_list_screen.dart';

class GymCatalogScreen extends StatelessWidget {
  final GymFirestoreService svc;

  const GymCatalogScreen({super.key, required this.svc});

  @override
  Widget build(BuildContext context) {
    return RoutinesListScreen(svc: svc);
  }
}


