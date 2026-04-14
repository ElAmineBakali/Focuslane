import 'package:flutter/material.dart';
import 'package:focuslane/screens/food/services/food_firestore_service.dart';
import 'food_settings_notifications_screen.dart';

class FoodSettingsScreen extends StatefulWidget {
  final FoodFirestoreService svc;

  const FoodSettingsScreen({super.key, required this.svc});

  @override
  State<FoodSettingsScreen> createState() => _FoodSettingsScreenState();
}

class _FoodSettingsScreenState extends State<FoodSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return FoodSettingsNotificationsScreen(
      svc: widget.svc,
      initialSection: FoodSettingsSection.configuracion,
    );
  }
}

