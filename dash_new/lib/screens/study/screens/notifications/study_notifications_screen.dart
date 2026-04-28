import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:focuslane/design/blocks/toast/app_toast.dart';
import 'package:focuslane/navigation/app_routes.dart';
import 'package:focuslane/screens/study/services/study_firestore_service.dart';
import 'package:focuslane/screens/study/services/study_notifications.dart';
import 'package:focuslane/design/ui/components/focus_card.dart';
import 'package:focuslane/design/ui/components/focus_section_title.dart';
import 'package:focuslane/design/ui/components/focus_module_header.dart';
import 'package:focuslane/design/ui/tokens/focuslane_tokens.dart';

class StudyNotificationsScreen extends StatefulWidget {
  final StudyFirestoreService svc;
  final VoidCallback? onBack;

  const StudyNotificationsScreen({super.key, required this.svc, this.onBack});

  @override
  State<StudyNotificationsScreen> createState() =>
      _StudyNotificationsScreenState();
}

class _StudyNotificationsScreenState extends State<StudyNotificationsScreen> {
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
    final notif = StudyNotifications(widget.svc);
    await notif.scheduleAll(classes: _notifyClasses, tasks: _notifyTasks);
  }

  @override
  Widget build(BuildContext context) {
    final header = FocusModuleHeader(
      title: 'Notificaciones',
      subtitle: 'Controla tus recordatorios de estudio',
      leadingMode: FocusModuleLeadingMode.backToModuleDashboard,
      onBack: widget.onBack,
      backRouteName: AppRoutes.studyDashboard,
    );

    if (_loading) {
      return Scaffold(
        appBar: header,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: header,
      body: SingleChildScrollView(
        padding: FocuslaneTokens.pagePaddingCompact,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const FocusSectionTitle(
              title: 'Notificaciones',
              subtitle: 'Controla tus recordatorios de estudio',
            ),
            FocusCard(
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    value: _notifyClasses,
                    onChanged: (v) => setState(() => _notifyClasses = v),
                    title: const Text('Recordatorios de clases'),
                    subtitle: const Text('Avisos antes de cada clase'),
                  ),
                  const Divider(height: 1),
                  SwitchListTile.adaptive(
                    value: _notifyTasks,
                    onChanged: (v) => setState(() => _notifyTasks = v),
                    title: const Text('Recordatorios de tareas'),
                    subtitle: const Text('Avisos de tareas pendientes'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: FocuslaneTokens.spacing12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () async {
                  await _save();
                  if (context.mounted) {
                    AppToast.success(context, 'Recordatorios actualizados');
                  }
                },
                child: const Text('Guardar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
