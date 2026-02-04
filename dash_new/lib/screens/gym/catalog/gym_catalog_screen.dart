import 'package:flutter/material.dart';
import '../../gym/services/gym_firestore_service.dart';
import '../../gym/routines/routines_list_screen.dart';

class GymCatalogScreen extends StatelessWidget {
  final GymFirestoreService svc;

  const GymCatalogScreen({super.key, required this.svc});

  @override
  Widget build(BuildContext context) {
    return RoutinesListScreen(svc: svc);
  }
}
