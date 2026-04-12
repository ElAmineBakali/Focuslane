import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:focuslane/core/services/core_sync_service.dart';
import 'package:focuslane/screens/home/home_dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isNotEmpty) {
      CoreSyncService.I.start(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const HomeDashboardScreen();
  }
}

