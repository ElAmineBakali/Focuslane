import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:mi_dashboard_personal/core/services/core_sync_service.dart';

const String _coreSyncUidOverride = String.fromEnvironment(
  'CORE_SYNC_UID',
  defaultValue: '',
);

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
        final hasDebugOverride =
            kDebugMode && _coreSyncUidOverride.trim().isNotEmpty;

        if (user == null) {
          CoreSyncService.I.stop();
          return unauthenticated;
        } else {
          final overrideUid = _coreSyncUidOverride.trim();
          if (hasDebugOverride && user.uid == overrideUid) {
            CoreSyncService.I.start(overrideUid);
          } else {
            if (hasDebugOverride && user.uid != overrideUid) {
              debugPrint(
                '[CoreSync][authGate] CORE_SYNC_UID ignored (auth uid=${user.uid}, override=$overrideUid)',
              );
            }
            CoreSyncService.I.start(user.uid);
          }

          // ── TEMPORARY DIAGNOSTIC ──
          return authenticated;
        }
      },
    );
  }
}
