import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mi_dashboard_personal/core/services/core_sync_service.dart';

class AuthGate extends StatelessWidget {
  final Widget authenticated;
  final Widget unauthenticated;

  const AuthGate({
    super.key,
    required this.authenticated,
    required this.unauthenticated,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          CoreSyncService.I.stop();
          return unauthenticated;
        } else {
          CoreSyncService.I.start(user.uid);
          return authenticated;
        }
      },
    );
  }
}
