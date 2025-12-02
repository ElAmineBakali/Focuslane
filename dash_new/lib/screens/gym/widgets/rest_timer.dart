import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/services/notification_service.dart'; // 🔔

class RestTimer extends StatefulWidget {
  final int initialSeconds; // p.ej. 90
  final VoidCallback? onFinished;

  const RestTimer({super.key, this.initialSeconds = 90, this.onFinished});

  @override
  State<RestTimer> createState() => _RestTimerState();
}

class _RestTimerState extends State<RestTimer> {
  late int _remaining;
  Timer? _t;
  bool _running = false;
  int? _notifId; // id de la noti programada para este timer

  @override
  void initState() {
    super.initState();
    _remaining = widget.initialSeconds;
  }

  Future<void> _start() async {
    _t?.cancel();
    setState(() => _running = true);

    // 🔔 programa noti exacta para cuando termine el descanso
    _notifId = DateTime.now().millisecondsSinceEpoch ^ hashCode;
    await NotificationService.I.scheduleOnce(
      id: _notifId!,
      title: 'Descanso terminado',
      body: 'Vuelve a la serie',
      whenLocal: DateTime.now().add(Duration(seconds: _remaining)),
      useExact: true,
    );

    _t = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining <= 1) {
        timer.cancel();
        setState(() {
          _remaining = 0;
          _running = false;
        });
        _notifId = null; // dejamos que la noti suene
        widget.onFinished?.call();
      } else {
        setState(() => _remaining--);
      }
    });
  }

  Future<void> _pause() async {
    _t?.cancel();
    setState(() => _running = false);
    if (_notifId != null) {
      await NotificationService.I.cancel(_notifId!);
      _notifId = null;
    }
  }

  Future<void> _reset([int? to]) async {
    _t?.cancel();
    if (_notifId != null) {
      await NotificationService.I.cancel(_notifId!);
      _notifId = null;
    }
    setState(() {
      _remaining = to ?? widget.initialSeconds;
      _running = false;
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    if (_notifId != null) {
      NotificationService.I.cancel(_notifId!); // best-effort
      _notifId = null;
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
              itemBuilder: (c) => const [
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
