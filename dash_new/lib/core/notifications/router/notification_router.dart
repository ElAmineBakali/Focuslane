import 'dart:convert';
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:mi_dashboard_personal/core/notifications/models/notification_action.dart';
import 'package:mi_dashboard_personal/core/notifications/models/notification_envelope.dart';
import 'package:mi_dashboard_personal/core/notifications/router/route_resolver.dart';

enum NotificationTapSource {
  local,
  push,
}

abstract class NotificationRouter {
  Future<void> handleTap({
    required String rawPayload,
    required NotificationTapSource source,
  });

  Future<void> handleEnvelope(NotificationEnvelope envelope);
  void attachNavigatorKey(GlobalKey<NavigatorState> navigatorKey);
}

class AppNotificationRouter implements NotificationRouter {
  AppNotificationRouter({required RouteResolver routeResolver})
      : _routeResolver = routeResolver;

  final RouteResolver _routeResolver;
  GlobalKey<NavigatorState>? _navigatorKey;
  NotificationEnvelope? _pendingEnvelope;

  @override
  void attachNavigatorKey(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
    final pending = _pendingEnvelope;
    if (pending == null) return;
    _pendingEnvelope = null;
    unawaited(handleEnvelope(pending));
  }

  @override
  Future<void> handleTap({
    required String rawPayload,
    required NotificationTapSource source,
  }) async {
    final envelope = _parseEnvelope(rawPayload);
    if (envelope == null) return;
    await handleEnvelope(envelope);
  }

  NotificationEnvelope? _parseEnvelope(String rawPayload) {
    try {
      final map = Map<String, dynamic>.from(jsonDecode(rawPayload) as Map);
      if ((map['v'] as num?)?.toInt() == 1 && map['notificationId'] != null) {
        return NotificationEnvelope.fromMap(map);
      }
      final nested = map['payload'];
      if (nested is String && nested.isNotEmpty) {
        return NotificationEnvelope.fromJson(nested);
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<void> handleEnvelope(NotificationEnvelope envelope) async {
    if (envelope.action.kind != NotificationActionKind.openRoute) {
      return;
    }

    final nav = _navigatorKey?.currentState;
    if (nav == null) {
      _pendingEnvelope = envelope;
      return;
    }

    final intent = _routeResolver.resolve(envelope);
    if (intent.replace) {
      nav.pushReplacementNamed(intent.route, arguments: intent.arguments);
      return;
    }
    nav.pushNamed(intent.route, arguments: intent.arguments);
  }
}
