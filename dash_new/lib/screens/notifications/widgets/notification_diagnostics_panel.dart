import 'package:flutter/material.dart';
import 'package:focuslane/core/notifications/push/notification_diagnostics_service.dart';

class NotificationDiagnosticsPanel extends StatefulWidget {
  const NotificationDiagnosticsPanel({super.key});

  @override
  State<NotificationDiagnosticsPanel> createState() =>
      _NotificationDiagnosticsPanelState();
}

class _NotificationDiagnosticsPanelState
    extends State<NotificationDiagnosticsPanel> {
  late Future<NotificationDiagnosticsSnapshot> _future;
  bool _sendingPush = false;
  bool _testingLocal = false;

  @override
  void initState() {
    super.initState();
    _future = NotificationDiagnosticsService.I.load();
  }

  void _reload() {
    setState(() {
      _future = NotificationDiagnosticsService.I.load();
    });
  }

  Future<void> _sendPushTest() async {
    setState(() => _sendingPush = true);
    try {
      await NotificationDiagnosticsService.I.sendTestPush();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Push de prueba encolado en Firebase')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo enviar el push: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _sendingPush = false);
        _reload();
      }
    }
  }

  Future<void> _sendLocalTest() async {
    setState(() => _testingLocal = true);
    try {
      await NotificationDiagnosticsService.I.sendLocalTest();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notificación local enviada')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo probar local: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _testingLocal = false);
        _reload();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FutureBuilder<NotificationDiagnosticsSnapshot>(
      future: _future,
      builder: (context, snapshot) {
        final data = snapshot.data;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: cs.surface,
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: cs.secondaryContainer,
                    ),
                    child: Icon(
                      Icons.health_and_safety_outlined,
                      color: cs.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Diagnóstico',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Estado real de permisos, FCM y entregas.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Actualizar estado',
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (snapshot.connectionState == ConnectionState.waiting &&
                  data == null)
                const LinearProgressIndicator()
              else if (snapshot.hasError)
                Text('No se pudo cargar el diagnóstico: ${snapshot.error}')
              else if (data != null) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatusChip(
                      label: 'Permiso',
                      value: data.permissionLabel,
                      ok: data.permissionGranted,
                    ),
                    _StatusChip(
                      label: 'Token FCM',
                      value: data.fcmTokenRegistered ? 'registrado' : 'ausente',
                      ok: data.fcmTokenRegistered,
                    ),
                    _StatusChip(
                      label: 'Tokens activos',
                      value: data.activeTokenCount?.toString() ?? 'no disponible',
                      ok: (data.activeTokenCount ?? 0) > 0,
                    ),
                    _StatusChip(
                      label: 'Exact alarms',
                      value: data.exactAlarmsAvailable == null
                          ? 'no aplica'
                          : data.exactAlarmsAvailable!
                              ? 'disponible'
                              : 'bloqueado',
                      ok: data.exactAlarmsAvailable != false,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _InfoLine(
                  icon: Icons.mark_email_read_outlined,
                  label: 'Último push',
                  value: data.lastPushReceived ?? 'Sin push registrado todavía',
                ),
                const SizedBox(height: 8),
                _InfoLine(
                  icon: Icons.error_outline,
                  label: 'Último error',
                  value: data.lastError ?? 'Sin errores registrados',
                ),
                const SizedBox(height: 10),
                Text(
                  data.explanation,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: _sendingPush ? null : _sendPushTest,
                      icon: _sendingPush
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.cloud_upload_outlined),
                      label: const Text('Enviar push de prueba'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _testingLocal ? null : _sendLocalTest,
                      icon: _testingLocal
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.notifications_active_outlined),
                      label: const Text('Probar notificación local'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.value,
    required this.ok,
  });

  final String label;
  final String value;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(
        ok ? Icons.check_circle_outline : Icons.warning_amber_outlined,
        size: 16,
      ),
      label: Text('$label · $value'),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: cs.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodySmall,
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

