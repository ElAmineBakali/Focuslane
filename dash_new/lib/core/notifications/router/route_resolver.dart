import 'package:mi_dashboard_personal/core/notifications/models/notification_action.dart';
import 'package:mi_dashboard_personal/core/notifications/models/notification_envelope.dart';
import 'package:mi_dashboard_personal/core/notifications/router/route_intent.dart';

abstract class RouteResolver {
  RouteIntent resolve(NotificationEnvelope envelope);
}

class DefaultRouteResolver implements RouteResolver {
  @override
  RouteIntent resolve(NotificationEnvelope envelope) {
    if (envelope.action.kind == NotificationActionKind.openRoute &&
        envelope.action.route != null &&
        envelope.action.route!.isNotEmpty) {
      return RouteIntent(route: envelope.action.route!, arguments: envelope.action.params);
    }

    switch (envelope.module.name) {
      case 'tasks':
        return const RouteIntent(route: '/tasks');
      case 'habits':
        return const RouteIntent(route: '/habits');
      case 'calendar':
        return const RouteIntent(route: '/calendar');
      default:
        return const RouteIntent(route: '/');
    }
  }
}
