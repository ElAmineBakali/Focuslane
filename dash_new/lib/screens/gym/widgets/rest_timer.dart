import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/material.dart';
import 'package:focuslane/core/notifications/local/android_channel_catalog.dart';
import 'package:focuslane/core/notifications/models/notification_action.dart';
import 'package:focuslane/core/notifications/models/notification_content.dart';
import 'package:focuslane/core/notifications/models/notification_delivery.dart';
import 'package:focuslane/core/notifications/models/notification_entity_ref.dart';
import 'package:focuslane/core/notifications/models/notification_intent.dart';
import 'package:focuslane/core/notifications/models/notification_schedule.dart';
import 'package:focuslane/core/notifications/notifications_facade.dart';

class RestTimer extends StatefulWidget {
  final int initialSeconds;
  final VoidCallback? onFinished;

  const RestTimer({super.key, this.initialSeconds = 90, this.onFinished});

  @override
  State<RestTimer> createState() => _RestTimerState();
}

class _RestTimerState extends State<RestTimer> {
  late int _remaining;
  Timer? _t;
  bool _running = false;
  String? _notificationId;
  @override
  void initState() {
    super.initState();
    _remaining = widget.initialSeconds;
  }

  Future<void> _start() async {
    _t?.cancel();
    setState(() => _running = true);

    final now = DateTime.now();
    final when = now.add(Duration(seconds: _remaining));
    final uid = fb_auth.FirebaseAuth.instance.currentUser?.uid ?? 'local';
    final entity = const NotificationEntityRef(
      module: NotificationModule.gym,
      kind: 'rest_timer',
      id: 'widget',
    );
    final notificationId =
        'ntf_gym_rest_timer_${when.toUtc().millisecondsSinceEpoch}_$hashCode';

    await NotificationsFacade.I.cancelByEntity(entity);
    await NotificationsFacade.I.scheduleIntent(
      NotificationIntent(
        module: NotificationModule.gym,
        type: 'REST_TIMER_FINISHED',
        entity: entity,
        content: const NotificationContent(
          title: 'Descanso terminado',
          body: 'Vuelve al ejercicio',
        ),
        action: const NotificationAction(
          kind: NotificationActionKind.openRoute,
          route: '/gym',
        ),
        schedule: NotificationSchedule(
          kind: NotificationScheduleKind.oneShot,
          scheduledAtUtc: when.toUtc(),
          timezone: when.timeZoneName,
        ),
        delivery: const NotificationDelivery(
          kind: NotificationDeliveryKind.localOnly,
          channel: AndroidChannelCatalog.gymReminders,
          priority: NotificationPriority.high,
        ),
        dedupeKey: 'gym:rest_timer:widget:$hashCode',
        userId: uid,
        source: 'gym.rest_timer_widget',
        notificationId: notificationId,
      ),
    );
    _notificationId = notificationId;

    _t = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining <= 1) {
        timer.cancel();
        setState(() {
          _remaining = 0;
          _running = false;
        });
        _notificationId = null;
        widget.onFinished?.call();
      } else {
        setState(() => _remaining--);
      }
    });
  }

  Future<void> _pause() async {
    _t?.cancel();
    setState(() => _running = false);
    if (_notificationId != null) {
      await NotificationsFacade.I.cancelByNotificationId(_notificationId!);
      _notificationId = null;
    }
  }

  Future<void> _reset([int? to]) async {
    _t?.cancel();
    if (_notificationId != null) {
      await NotificationsFacade.I.cancelByNotificationId(_notificationId!);
      _notificationId = null;
    }
    setState(() {
      _remaining = to ?? widget.initialSeconds;
      _running = false;
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    if (_notificationId != null) {
      NotificationsFacade.I.cancelByNotificationId(_notificationId!);
      _notificationId = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = (_remaining ~/ 60).toString().padLeft(2, '0');
    final s = (_remaining % 60).toString().padLeft(2, '0');
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(.4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$m:$s', style: theme.textTheme.titleLarge),
            const SizedBox(width: 8),
            if (!_running)
              IconButton(
                tooltip: 'Start',
                onPressed: _start,
                icon: const Icon(Icons.play_arrow_rounded),
              )
            else
              IconButton(
                tooltip: 'Pause',
                onPressed: _pause,
                icon: const Icon(Icons.pause_rounded),
              ),
            IconButton(
              tooltip: 'Reset',
              onPressed: () => _reset(),
              icon: const Icon(Icons.restart_alt_rounded),
            ),
            PopupMenuButton<int>(
              tooltip: 'Preset',
              itemBuilder:
                  (c) => const [
                    PopupMenuItem(value: 60, child: Text('60s')),
                    PopupMenuItem(value: 90, child: Text('90s')),
                    PopupMenuItem(value: 120, child: Text('120s')),
                    PopupMenuItem(value: 180, child: Text('180s')),
                  ],
              onSelected: (v) => _reset(v),
              icon: const Icon(Icons.timer_outlined),
            ),
          ],
        ),
      ),
    );
  }
}
