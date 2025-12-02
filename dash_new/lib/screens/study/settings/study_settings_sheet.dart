import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/study_firestore_service.dart';
import '../services/study_notifications.dart';

class StudySettingsSheet extends StatefulWidget {
  final StudyFirestoreService svc;
  const StudySettingsSheet({super.key, required this.svc});

  @override
  State<StudySettingsSheet> createState() => _StudySettingsSheetState();
}

class _StudySettingsSheetState extends State<StudySettingsSheet> {
  static const _kNotifyClasses = 'study_notify_classes';
  static const _kNotifyTasks = 'study_notify_tasks';

  bool _notifyClasses = true;
  bool _notifyTasks = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notifyClasses = prefs.getBool(_kNotifyClasses) ?? true;
      _notifyTasks = prefs.getBool(_kNotifyTasks) ?? true;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotifyClasses, _notifyClasses);
    await prefs.setBool(_kNotifyTasks, _notifyTasks);
  }

  Future<void> _reschedule() async {
    final notif = StudyNotifications(widget.svc);
    await notif.scheduleAll(classes: _notifyClasses, tasks: _notifyTasks);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recordatorios reprogramados')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 12,
      ),
      child: SafeArea(
        child:
            _loading
                ? const SizedBox(
                  height: 160,
                  child: Center(child: CircularProgressIndicator()),
                )
                : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.settings),
                        const SizedBox(width: 8),
                        Text(
                          'Ajustes de Study',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Cerrar',
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      value: _notifyClasses,
                      onChanged: (v) => setState(() => _notifyClasses = v),
                      title: const Text('Recordatorios de clases'),
                      subtitle: const Text('15 minutos antes de cada bloque'),
                    ),
                    SwitchListTile(
                      value: _notifyTasks,
                      onChanged: (v) => setState(() => _notifyTasks = v),
                      title: const Text('Recordatorios de tareas / exámenes'),
                      subtitle: const Text(
                        'Un día antes y el mismo día a las 8:00',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () async {
                            await _save();
                            await _reschedule();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Guardar y reprogramar'),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () async {
                            await _save();
                            if (mounted) Navigator.pop(context);
                          },
                          child: const Text('Guardar'),
                        ),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
      ),
    );
  }
}
