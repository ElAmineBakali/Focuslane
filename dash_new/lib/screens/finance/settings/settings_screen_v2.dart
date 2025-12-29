import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mi_dashboard_personal/theme/finance_ui_theme.dart';
import 'package:mi_dashboard_personal/services/finance/settings_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'dart:io';

class SettingsScreenV2 extends StatefulWidget {
  const SettingsScreenV2({super.key});
  static const route = '/finance/settings';

  @override
  State<SettingsScreenV2> createState() => _SettingsScreenV2State();
}

class _SettingsScreenV2State extends State<SettingsScreenV2> {
  final _localAuth = LocalAuthentication();
  final _secureStorage = const FlutterSecureStorage();
  
  bool _biometricsEnabled = false;
  bool _pinEnabled = false;
  bool _notificationsEnabled = true;
  bool _budgetAlerts = true;
  bool _subscriptionReminders = true;
  int _subscriptionReminderDays = 3;
  double _budgetAlertPercent = 0.8;
  bool _dailySummary = false;
  TimeOfDay _summaryTime = const TimeOfDay(hour: 9, minute: 0);
  String _currency = 'EUR';
  bool _canCheckBiometrics = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkBiometrics();
  }

  Future<void> _loadSettings() async {
    final settings = await FinanceSettingsService.I.getSettings();
    final pinExists = await _secureStorage.read(key: 'finance_pin');
    setState(() {
      _biometricsEnabled = settings['biometricsEnabled'] ?? false;
      _pinEnabled = pinExists != null;
      _notificationsEnabled = settings['notificationsEnabled'] ?? true;
      _budgetAlerts = settings['budgetAlerts'] ?? true;
      _subscriptionReminders = settings['subscriptionReminders'] ?? true;
      _subscriptionReminderDays = settings['subscriptionReminderDays'] ?? 3;
      _budgetAlertPercent = (settings['budgetAlertPercent'] as num?)?.toDouble() ?? 0.8;
      _dailySummary = settings['dailySummary'] ?? false;
      final timeStr = settings['summaryTime'] as String?;
      if (timeStr != null && timeStr.contains(':')) {
        final parts = timeStr.split(':');
        final h = int.tryParse(parts[0]) ?? 9;
        final m = int.tryParse(parts[1]) ?? 0;
        _summaryTime = TimeOfDay(hour: h, minute: m);
      }
      _currency = settings['currency'] ?? 'EUR';
    });
  }

  Future<void> _checkBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      setState(() => _canCheckBiometrics = canCheck);
    } catch (e) {
      setState(() => _canCheckBiometrics = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          FinanceUI.sliverAppBar(
            context,
            title: 'Configuración',
            backgroundIcon: Icons.settings,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSecuritySection(),
                  const SizedBox(height: 24),
                  _buildNotificationsSection(),
                  const SizedBox(height: 24),
                  _buildGeneralSection(),
                  const SizedBox(height: 24),
                  _buildDataSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildSecuritySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.security, size: 20),
                const SizedBox(width: 8),
                Text('Seguridad', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
              ],
            ),
            const Divider(height: 24),
            if (_canCheckBiometrics)
              SwitchListTile(
                title: const Text('Autenticación biométrica'),
                subtitle: const Text('Huella digital / Face ID'),
                value: _biometricsEnabled,
                onChanged: (v) async {
                  if (v) {
                    final authenticated = await _localAuth.authenticate(
                      localizedReason: 'Activa la autenticación biométrica',
                      biometricOnly: true,
                    );
                    if (authenticated) {
                      await FinanceSettingsService.I.updateSetting('biometricsEnabled', true);
                      setState(() => _biometricsEnabled = true);
                    }
                  } else {
                    await FinanceSettingsService.I.updateSetting('biometricsEnabled', false);
                    setState(() => _biometricsEnabled = false);
                  }
                },
                contentPadding: EdgeInsets.zero,
              ),
            SwitchListTile(
              title: const Text('PIN de acceso'),
              subtitle: _pinEnabled ? const Text('PIN configurado') : const Text('Sin PIN'),
              value: _pinEnabled,
              onChanged: (v) async {
                if (v) {
                  await _showPinSheet(isChange: false);
                } else {
                  await _secureStorage.delete(key: 'finance_pin');
                  setState(() => _pinEnabled = false);
                }
              },
              contentPadding: EdgeInsets.zero,
            ),
            if (_pinEnabled)
              ListTile(
                title: const Text('Cambiar PIN'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showPinSheet(isChange: true),
                contentPadding: EdgeInsets.zero,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications, size: 20),
                const SizedBox(width: 8),
                Text('Notificaciones', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
              ],
            ),
            const Divider(height: 24),
            SwitchListTile(
              title: const Text('Notificaciones generales'),
              subtitle: const Text('Activar/desactivar todas'),
              value: _notificationsEnabled,
              onChanged: (v) async {
                await FinanceSettingsService.I.updateSetting('notificationsEnabled', v);
                setState(() => _notificationsEnabled = v);
              },
              contentPadding: EdgeInsets.zero,
            ),
            if (_notificationsEnabled) ...[
              SwitchListTile(
                title: const Text('Alertas de presupuesto'),
                subtitle: const Text('Avisos al superar límites'),
                value: _budgetAlerts,
                onChanged: (v) async {
                  await FinanceSettingsService.I.updateSetting('budgetAlerts', v);
                  setState(() => _budgetAlerts = v);
                },
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile(
                title: const Text('Recordatorios de suscripciones'),
                subtitle: Text('Avisos antes del pago (${_subscriptionReminderDays} día(s) antes)'),
                value: _subscriptionReminders,
                onChanged: (v) async {
                  await FinanceSettingsService.I.updateSetting('subscriptionReminders', v);
                  setState(() => _subscriptionReminders = v);
                },
                contentPadding: EdgeInsets.zero,
              ),
              if (_subscriptionReminders)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text('Días antes del cobro', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    Slider(
                      value: _subscriptionReminderDays.toDouble(),
                      min: 1,
                      max: 7,
                      divisions: 6,
                      label: '$_subscriptionReminderDays',
                      onChanged: (v) async {
                        final days = v.round();
                        await FinanceSettingsService.I.updateSetting('subscriptionReminderDays', days);
                        setState(() => _subscriptionReminderDays = days);
                      },
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              Text('Resumen diario', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              SwitchListTile(
                title: const Text('Recibir resumen diario'),
                subtitle: Text('A las ${_summaryTime.format(context)}'),
                value: _dailySummary,
                onChanged: (v) async {
                  await FinanceSettingsService.I.updateSetting('dailySummary', v);
                  setState(() => _dailySummary = v);
                },
                contentPadding: EdgeInsets.zero,
              ),
              if (_dailySummary)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.schedule),
                  title: const Text('Hora del resumen'),
                  subtitle: Text(_summaryTime.format(context)),
                  onTap: () async {
                    final picked = await showTimePicker(context: context, initialTime: _summaryTime);
                    if (picked != null) {
                      await FinanceSettingsService.I.updateSetting('summaryTime', '${picked.hour}:${picked.minute}');
                      setState(() => _summaryTime = picked);
                    }
                  },
                ),
              const SizedBox(height: 8),
              Text('Umbral de alerta de presupuesto', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              Slider(
                value: _budgetAlertPercent,
                min: 0.5,
                max: 1.0,
                divisions: 5,
                label: '${(_budgetAlertPercent * 100).round()}%',
                onChanged: (v) async {
                  await FinanceSettingsService.I.updateSetting('budgetAlertPercent', v);
                  setState(() => _budgetAlertPercent = v);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.tune, size: 20),
                const SizedBox(width: 8),
                Text('General', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
              ],
            ),
            const Divider(height: 24),
            ListTile(
              title: const Text('Moneda predeterminada'),
              subtitle: Text(_currency),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () async {
                final selected = await showDialog<String>(
                  context: context,
                  builder: (ctx) => SimpleDialog(
                    title: const Text('Selecciona moneda'),
                    children: ['EUR', 'USD', 'GBP', 'JPY', 'CHF', 'CAD', 'AUD']
                        .map((c) => SimpleDialogOption(
                              onPressed: () => Navigator.pop(ctx, c),
                              child: Text(c),
                            ))
                        .toList(),
                  ),
                );
                if (selected != null) {
                  await FinanceSettingsService.I.updateSetting('currency', selected);
                  setState(() => _currency = selected);
                }
              },
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPinSheet({required bool isChange}) async {
    final formKey = GlobalKey<FormState>();
    final pin1 = TextEditingController();
    final pin2 = TextEditingController();
    final existingPin = await _secureStorage.read(key: 'finance_pin');

    if (isChange && existingPin != null) {
      final ok = await _verifyPin(existingPin);
      if (!ok) return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: FinanceUI.modalCard(
            context: ctx,
            title: isChange ? 'Cambia tu PIN' : 'Crea tu PIN',
            icon: Icons.lock_outline,
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Usaremos este PIN para proteger el módulo de finanzas.', style: GoogleFonts.poppins()),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: pin1,
                    obscureText: true,
                    maxLength: 4,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: 'PIN (4 dígitos)'),
                    validator: (v) => (v == null || v.length != 4) ? 'PIN de 4 dígitos' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: pin2,
                    obscureText: true,
                    maxLength: 4,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: 'Confirmar PIN'),
                    validator: (v) => v != pin1.text ? 'No coincide' : null,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text('Guardar PIN'),
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        await _secureStorage.write(key: 'finance_pin', value: pin1.text);
                        await FinanceSettingsService.I.updateSetting('pinEnabled', true);
                        if (mounted) {
                          setState(() => _pinEnabled = true);
                          Navigator.pop(ctx);
                          _showNiceSnack('PIN guardado');
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    pin1.dispose();
    pin2.dispose();
  }

  Future<bool> _verifyPin(String expected) async {
    final ctrl = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: FinanceUI.modalCard(
            context: ctx,
            title: 'Introduce tu PIN',
            icon: Icons.lock,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: ctrl,
                  obscureText: true,
                  maxLength: 4,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'PIN'),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Validar'),
                    onPressed: () => Navigator.pop(ctx, ctrl.text == expected),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    ctrl.dispose();
    if (ok != true) {
      _showNiceSnack('PIN incorrecto');
      return false;
    }
    return true;
  }

  void _showNiceSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: GoogleFonts.poppins())),
          ],
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildDataSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.storage, size: 20),
                const SizedBox(width: 8),
                Text('Datos', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
              ],
            ),
            const Divider(height: 24),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Exportar a CSV'),
              subtitle: const Text('Descarga tus datos'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _showExportDialog,
              contentPadding: EdgeInsets.zero,
            ),
            ListTile(
              leading: const Icon(Icons.backup),
              title: const Text('Respaldo de datos'),
              subtitle: const Text('Copia de seguridad en la nube'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Función próximamente', style: GoogleFonts.poppins()),
                  ),
                );
              },
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPinSetupDialog() async {
    final pinCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_pinEnabled ? 'Cambiar PIN' : 'Configurar PIN', style: GoogleFonts.poppins()),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: pinCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nuevo PIN',
                  hintText: '4 dígitos',
                ),
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (v == null || v.length != 4) return 'Debe tener 4 dígitos';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmCtrl,
                decoration: const InputDecoration(
                  labelText: 'Confirmar PIN',
                  hintText: '4 dígitos',
                ),
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (v != pinCtrl.text) return 'Los PIN no coinciden';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _secureStorage.write(key: 'finance_pin', value: pinCtrl.text);
      setState(() => _pinEnabled = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PIN configurado', style: GoogleFonts.poppins())),
        );
      }
    }
  }

  Future<void> _showExportDialog() async {
    DateTime? startDate;
    DateTime? endDate;

    final result = await showDialog<Map<String, DateTime?>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Exportar datos', style: GoogleFonts.poppins()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Desde'),
                subtitle: Text(startDate != null ? DateFormat('d MMM yyyy').format(startDate!) : 'Seleccionar'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: startDate ?? DateTime.now().subtract(const Duration(days: 30)),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setDialogState(() => startDate = picked);
                  }
                },
              ),
              ListTile(
                title: const Text('Hasta'),
                subtitle: Text(endDate != null ? DateFormat('d MMM yyyy').format(endDate!) : 'Seleccionar'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: endDate ?? DateTime.now(),
                    firstDate: startDate ?? DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setDialogState(() => endDate = picked);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: startDate != null && endDate != null
                  ? () => Navigator.pop(ctx, {'start': startDate, 'end': endDate})
                  : null,
              child: const Text('Exportar'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      await _exportToCSV(result['start']!, result['end']!);
    }
  }

  Future<void> _exportToCSV(DateTime start, DateTime end) async {
    try {
      final csvPath = await FinanceSettingsService.I.exportTransactionsToCSV(start, end);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exportado a: $csvPath', style: GoogleFonts.poppins()),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Abrir',
              onPressed: () {
                // Open file manager to the location
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al exportar: $e', style: GoogleFonts.poppins())),
        );
      }
    }
  }
}
