import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kDebugMode, kIsWeb;
import 'package:focuslane/core/notifications/push/notification_diagnostics_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class FcmTokenSyncService {
  FcmTokenSyncService._();

  static final FcmTokenSyncService I = FcmTokenSyncService._();

  static const String _deviceIdKey = 'push_device_id_v1';

  StreamSubscription<fb_auth.User?>? _authSub;
  StreamSubscription<String>? _tokenRefreshSub;
  String? _lastUserId;
  bool _started = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;

    if (kIsWeb) {
      // Web FCM setup can be optional during development.
      return;
    }

    _authSub = fb_auth.FirebaseAuth.instance.authStateChanges().listen((user) async {
      await _onAuthChanged(user);
    });

    _tokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      final user = fb_auth.FirebaseAuth.instance.currentUser;
      if (user == null || token.trim().isEmpty) return;
      try {
        await _upsertToken(user: user, token: token);
        } catch (e) {
          await NotificationDiagnosticsService.I.recordError(e);
          if (kDebugMode) {
          // Ignore push sync errors outside supported FCM environments.
          // ignore: avoid_print
          print('[FCM] token refresh sync skipped: $e');
        }
      }
    });

    final currentUser = fb_auth.FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await _syncCurrentToken(currentUser);
      _lastUserId = currentUser.uid;
    }
  }

  Future<void> _onAuthChanged(fb_auth.User? user) async {
    final previous = _lastUserId;
    final next = user?.uid;

    if (previous != null && previous != next) {
      await _revokeToken(previous);
    }

    if (user != null) {
      await _syncCurrentToken(user);
      _lastUserId = user.uid;
      return;
    }

    _lastUserId = null;
  }

  Future<void> _syncCurrentToken(fb_auth.User user) async {
    String? token;
    try {
      token = await FirebaseMessaging.instance.getToken();
    } catch (e) {
      await NotificationDiagnosticsService.I.recordError(e);
      if (kDebugMode) {
        // ignore: avoid_print
        print('[FCM] getToken skipped: $e');
      }
      return;
    }
    if (token == null || token.trim().isEmpty) return;
    await _upsertToken(user: user, token: token);
  }

  Future<void> _upsertToken({
    required fb_auth.User user,
    required String token,
  }) async {
    final deviceId = await _getOrCreateDeviceId();
    final now = DateTime.now().toUtc();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('push_tokens')
        .doc(deviceId)
        .set({
      'deviceId': deviceId,
      'token': token,
      'platform': _platformName(),
      'timezone': now.timeZoneName,
      'appVersion': 'unknown',
      'updatedAt': FieldValue.serverTimestamp(),
      'isActive': true,
    }, SetOptions(merge: true));
  }

  Future<void> _revokeToken(String uid) async {
    final deviceId = await _getOrCreateDeviceId();
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('push_tokens')
        .doc(deviceId)
        .set({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
      'revokedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<String> _getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_deviceIdKey);
    if (existing != null && existing.trim().isNotEmpty) {
      return existing;
    }

    final created = const Uuid().v4();
    await prefs.setString(_deviceIdKey, created);
    return created;
  }

  String _platformName() {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform.name;
  }

  void dispose() {
    _authSub?.cancel();
    _authSub = null;
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    _started = false;
  }
}
