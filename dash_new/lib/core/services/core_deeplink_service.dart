import 'package:flutter/material.dart';

import '../constants/core_routes.dart';
import '../models/core_entity_ref.dart';
import '../../ui/feedback/focus_feedback.dart';

class CoreDeeplinkService {
  CoreDeeplinkService._();
  static final CoreDeeplinkService I = CoreDeeplinkService._();

  ({String route, Object? args}) resolveRefToRoute(CoreEntityRef ref) {
    String routeName = ref.routeName.isNotEmpty ? ref.routeName : CoreRoutes.home;
    Object? args = ref.routeArgs.isNotEmpty ? ref.routeArgs : null;

    switch (ref.type) {
      case CoreEntityType.task:
        routeName = CoreRoutes.tasks;
        args = ref.routeArgs.isNotEmpty ? ref.routeArgs : {'highlightId': ref.id};
        break;
      case CoreEntityType.note:
        routeName = '/notes/editor';
        args = ref.routeArgs.isNotEmpty ? ref.routeArgs : {'noteId': ref.id};
        break;
      case CoreEntityType.foodIntakeEntry:
      case CoreEntityType.foodRecipe:
      case CoreEntityType.foodFoodItem:
        routeName = CoreRoutes.foodDashboard;
        args = ref.routeArgs.isNotEmpty ? ref.routeArgs : {'dayId': ref.dayId};
        break;
      case CoreEntityType.gymSession:
        routeName = CoreRoutes.gymDashboard;
        break;
      case CoreEntityType.studySession:
        routeName = CoreRoutes.studyDashboard;
        break;
      case CoreEntityType.financeTransaction:
        routeName = CoreRoutes.financeTransactions;
        break;
      case CoreEntityType.calendarEvent:
        routeName = '/calendar';
        break;
    }

    return (route: routeName, args: args);
  }

  Future<void> safeNavigate(BuildContext context, CoreEntityRef ref) async {
    if (ref.id.isEmpty && ref.routeArgs.isEmpty) {
      FocusFeedback.showError(context, 'No se puede abrir este elemento');
      return;
    }
    final resolved = resolveRefToRoute(ref);
    const allowedRoutes = {
      CoreRoutes.home,
      CoreRoutes.tasks,
      CoreRoutes.foodDashboard,
      CoreRoutes.gymDashboard,
      CoreRoutes.studyDashboard,
      CoreRoutes.financeTransactions,
      CoreRoutes.coreHub,
      '/calendar',
      '/notes/editor',
    };
    if (resolved.route.isEmpty || !allowedRoutes.contains(resolved.route)) {
      FocusFeedback.showError(context, 'No se puede abrir este elemento');
      return;
    }
    try {
      await Navigator.of(context).pushNamed(resolved.route, arguments: resolved.args);
    } catch (_) {
      FocusFeedback.showError(context, 'No se pudo abrir este elemento');
    }
  }
}
