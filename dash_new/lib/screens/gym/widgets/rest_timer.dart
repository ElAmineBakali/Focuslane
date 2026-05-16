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
import 'package:focuslane/design/ui/focuslane_ui.dart';

class RestTimer extends StatefulWidget {
  const RestTimer({super.key, this.initialSeconds = 90, this.onFinished});

  final int initialSeconds;
  final VoidCallback? onFinished;

  @override
  State<RestTimer> createState() => _RestTimerState();
}

class _RestTimerState extends State<RestTimer> {
  late int _remaining;
  Timer? _timer;
  var _running = false;
  String? _notificationId;

  @override
  void initState() {
    super.initState();
    _remaining = widget.initialSeconds;
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_notificationId != null) {
      NotificationsFacade.I.cancelByNotificationId(_notificationId!);
      _notificationId = null;
    }
    super.dispose();
  }

  Future<void> _start() async {
    _timer?.cancel();
    setState(() => _running = true);

    final now = DateTime.now();
    final when = now.add(Duration(seconds: _remaining));
    final uid = fb_auth.FirebaseAuth.instance.currentUser?.uid ?? 'local';
    const entity = NotificationEntityRef(
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

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
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
    _timer?.cancel();
    setState(() => _running = false);
    if (_notificationId != null) {
      await NotificationsFacade.I.cancelByNotificationId(_notificationId!);
      _notificationId = null;
    }
  }

  Future<void> _reset([int? seconds]) async {
    _timer?.cancel();
    if (_notificationId != null) {
      await NotificationsFacade.I.cancelByNotificationId(_notificationId!);
      _notificationId = null;
    }
    setState(() {
      _remaining = seconds ?? widget.initialSeconds;
      _running = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = widget.initialSeconds == 0 ? 1 : widget.initialSeconds;
    final progress = 1 - (_remaining / total).clamp(0.0, 1.0);
    final minutes = (_remaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remaining % 60).toString().padLeft(2, '0');

    return FocusCard(
      padding: const EdgeInsets.all(18),
      backgroundColor: scheme.surfaceContainerLowest,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FocusProgressRing(
            value: progress,
            size: 150,
            strokeWidth: 12,
            label: '$minutes:$seconds',
            subtitle: 'descanso',
            color: scheme.primary,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              FocusIconButton(
                icon: _running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                tooltip: _running ? 'Pausar descanso' : 'Iniciar descanso',
                onPressed: _running ? _pause : _start,
              ),
              FocusIconButton(
                icon: Icons.restart_alt_rounded,
                tooltip: 'Reiniciar descanso',
                onPressed: () => _reset(),
              ),
              PopupMenuButton<int>(
                tooltip: 'Duración',
                icon: const Icon(Icons.timer_outlined),
                onSelected: _reset,
                itemBuilder:
                    (_) => const [
                      PopupMenuItem(value: 60, child: Text('60 segundos')),
                      PopupMenuItem(value: 90, child: Text('90 segundos')),
                      PopupMenuItem(value: 120, child: Text('120 segundos')),
                      PopupMenuItem(value: 180, child: Text('180 segundos')),
                    ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
