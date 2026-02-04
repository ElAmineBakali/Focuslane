import 'package:flutter/material.dart';
import '../services/food_firestore_service.dart';
import 'food_settings_notifications_screen.dart';

class FoodNotificationsScreen extends StatelessWidget {
  final FoodFirestoreService svc;
  const FoodNotificationsScreen({super.key, required this.svc});

  @override
  Widget build(BuildContext context) {
    return FoodSettingsNotificationsScreen(
      svc: svc,
      initialSection: FoodSettingsSection.notificaciones,
    );
  }
}

