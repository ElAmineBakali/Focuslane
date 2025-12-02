import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FinanceSettingsScreen extends StatefulWidget {
  const FinanceSettingsScreen({super.key});
  static const route = '/finance/settings';

  @override
  State<FinanceSettingsScreen> createState() => _FinanceSettingsScreenState();
}

class _FinanceSettingsScreenState extends State<FinanceSettingsScreen> {
  final _currency = TextEditingController(text: 'EUR');
  int _monthStartDay = 1; // Fijado a 1 por tu requisito, igualmente editable si quisieras cambiarlo
  double _budgetsAlertPct = 80; // alerta de presupuestos (%)
  int _fixedRemindDays = 3; // recordar X días antes
  bool _pinLock = false;

  bool _loading = true;
  String get _uid => FirebaseAuth.instance.currentUser!.uid;
  DocumentReference<Map<String, dynamic>> get _metaDoc =>
      FirebaseFirestore.instance.collection('users').doc(_uid).collection('finance').doc('meta');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final snap = await _metaDoc.get();
      final data = snap.data() ?? {};
      final settings = (data['settings'] as Map?) ?? {};
      setState(() {
        _currency.text = (settings['currency'] ?? 'EUR').toString();
        _monthStartDay = (settings['monthStartDay'] ?? 1) as int;
        final notif = (settings['notifications'] as Map?) ?? {};
        _budgetsAlertPct = ((notif['budgetsThresholdPct'] ?? 80) as num).toDouble();
        _fixedRemindDays = (notif['remindFixedDaysBefore'] ?? 3) as int;
        _pinLock = (settings['pinLock'] ?? false) as bool;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    await _metaDoc.set({
      'settings': {
        'currency': _currency.text.trim().isEmpty ? 'EUR' : _currency.text.trim(),
        'monthStartDay': _monthStartDay, // queda 1 como acordamos
        'pinLock': _pinLock,
        'notifications': {
          'budgetsThresholdPct': _budgetsAlertPct,
          'remindFixedDaysBefore': _fixedRemindDays,
        },
      }
    }, SetOptions(merge: true));
    if (mounted) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ajustes guardados')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes de finanzas')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Generales', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _currency,
                          decoration: const InputDecoration(
                            labelText: 'Divisa principal (p.ej. EUR)',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Expanded(child: Text('Inicio de mes financiero')),
                            DropdownButton<int>(
                              value: _monthStartDay,
                              onChanged: (v) {
                                // Si prefieres dejarlo fijo a 1, comenta el setState:
                                setState(() => _monthStartDay = v ?? 1);
                              },
                              items: List.generate(28, (i) => i + 1)
                                  .map((d) => DropdownMenuItem(value: d, child: Text('$d')))
                                  .toList(),
                            ),
                          ],
                        ),
                        SwitchListTile(
                          title: const Text('Bloqueo con PIN/Biometría (solo módulo de finanzas)'),
                          value: _pinLock,
                          onChanged: (v) => setState(() => _pinLock = v),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Notificaciones', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Aviso de presupuesto al (%)'),
                          trailing: SizedBox(
                            width: 96,
                            child: TextField(
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(suffixText: '%'),
                              controller: TextEditingController(text: _budgetsAlertPct.toStringAsFixed(0)),
                              onChanged: (v) {
                                final x = double.tryParse(v);
                                if (x != null) _budgetsAlertPct = x.clamp(0, 100);
                              },
                            ),
                          ),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Recordar gastos fijos (días antes)'),
                          trailing: DropdownButton<int>(
                            value: _fixedRemindDays,
                            onChanged: (v) => setState(() => _fixedRemindDays = v ?? 3),
                            items: const [0, 1, 2, 3, 5, 7, 10]
                                .map((d) => DropdownMenuItem(value: d, child: Text('$d')))
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar'),
                  onPressed: _save,
                ),
              ],
            ),
    );
  }
}
