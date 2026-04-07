import 'package:hive_flutter/hive_flutter.dart';
import 'package:mi_dashboard_personal/core/notifications/contracts/notification_clock.dart';
import 'package:mi_dashboard_personal/core/notifications/contracts/notification_logger.dart';
import 'package:mi_dashboard_personal/core/notifications/local/flutter_local_notification_gateway.dart';
import 'package:mi_dashboard_personal/core/notifications/local/local_id_generator.dart';
import 'package:mi_dashboard_personal/core/notifications/local/local_scheduler.dart';
import 'package:mi_dashboard_personal/core/notifications/mapping/intent_to_envelope_mapper.dart';
import 'package:mi_dashboard_personal/core/notifications/notification_manager.dart';
import 'package:mi_dashboard_personal/core/notifications/policies/dedupe_policy.dart';
import 'package:mi_dashboard_personal/core/notifications/policies/notification_policy_engine.dart';
import 'package:mi_dashboard_personal/core/notifications/registry/hive_notification_registry_repository.dart';
import 'package:mi_dashboard_personal/core/notifications/router/notification_router.dart';
import 'package:mi_dashboard_personal/core/notifications/router/route_resolver.dart';

class NotificationsBootstrap {
  NotificationsBootstrap._internal();

  static final NotificationsBootstrap instance = NotificationsBootstrap._internal();

  NotificationManager? _manager;
  NotificationManager get manager {
    final m = _manager;
    if (m == null) {
      throw StateError('NotificationsBootstrap not initialized. Call init() first.');
    }
    return m;
  }
  bool _initialized = false;

  NotificationManager _buildManager(HiveNotificationRegistryRepository registry) {
    final mapper = DefaultIntentToEnvelopeMapper(SystemNotificationClock());
    final gateway = FlutterLocalNotificationGateway();
    final manager = NotificationManager(
      localScheduler: DefaultLocalScheduler(
        gateway: gateway,
        idGenerator: FnvLocalIdGenerator(),
      ),
      registry: registry,
      policyEngine: AllowAllNotificationPolicyEngine(),
      dedupePolicy: DedupePolicy(registry),
      mapper: mapper,
      router: AppNotificationRouter(routeResolver: DefaultRouteResolver()),
      clock: SystemNotificationClock(),
      logger: DebugPrintNotificationLogger(),
    );
    gateway.setTapHandler(manager.handleTapPayload);
    return manager;
  }

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    await Hive.initFlutter();
    final registry = await HiveNotificationRegistryRepository.create();
    _manager = _buildManager(registry);

    await manager.init();
  }

  Future<void> dispose() async {
    return;
  }
}
