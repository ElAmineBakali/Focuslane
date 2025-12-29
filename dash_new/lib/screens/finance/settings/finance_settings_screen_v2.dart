import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/theme/finance_ui_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:csv/csv.dart';
import 'package:mi_dashboard_personal/services/finance/transaction_service.dart';
import 'package:mi_dashboard_personal/services/notification_service.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';

class FinanceSettingsScreenV2 extends StatefulWidget {
  const FinanceSettingsScreenV2({super.key});
  static const route = '/finance/settings';

  @override
  State<FinanceSettingsScreenV2> createState() =>
      _FinanceSettingsScreenV2State();
}

class _FinanceSettingsScreenV2State extends State<FinanceSettingsScreenV2> {
  final _storage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();
  bool _biometricsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final bio = await _storage.read(key: 'finance_biometrics') ?? 'false';
    setState(() => _biometricsEnabled = bio == 'true');
  }

  Future<void> _toggleBiometrics() async {
    final can = await _localAuth.canCheckBiometrics;
    if (!can) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Biometría no disponible')));
      return;
    }

    final auth = await _localAuth.authenticate(
      localizedReason: 'Autenticarse para activar biometría',
    );
    if (!auth) return;

    final next = !_biometricsEnabled;
    await _storage.write(key: 'finance_biometrics', value: next.toString());
    setState(() => _biometricsEnabled = next);
  }

  Future<void> _exportCSV() async {
    final txs = await TransactionService.I.watch().first;
    final rows = [
      [
        'Date',
        'Type',
        'Title',
        'Amount',
        'Category',
        'SubCategory',
        'Account',
        'Notes',
        'Tags',
      ],
    ];
    for (final t in txs) {
      rows.add([
        t.date.toIso8601String(),
        t.type.name,
        t.title,
        t.amount.toStringAsFixed(2),
        t.category ?? '',
        t.subCategory ?? '',
        t.accountId ?? '',
        t.notes ?? '',
        t.tags.join('; '),
      ]);
    }

    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/transactions_export.csv');
    await file.writeAsString(csv);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Exportado a ${file.path}')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FinanceScreenBody(
        slivers: [
          const FinanceHeaderLarge(
            title: 'Ajustes',
            icon: Icons.settings_outlined,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              child: FinanceFormTheme(
                child: Column(
                  children: [
                    FinanceCard(
                      child: SwitchListTile(
                        secondary: const Icon(Icons.fingerprint),
                        title: Text(
                          'Protección biométrica',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: const Text(
                          'Requerir autenticación para acceder',
                        ),
                        value: _biometricsEnabled,
                        onChanged: (_) => _toggleBiometrics(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FinanceCard(
                      child: ListTile(
                        leading: const Icon(Icons.notifications_outlined),
                        title: Text(
                          'Recordatorios',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: const Text(
                          'Gestionar alertas de presupuestos y suscripciones',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // Navigate to notification config
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    FinanceCard(
                      child: ListTile(
                        leading: const Icon(Icons.download),
                        title: Text(
                          'Exportar CSV',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: const Text(
                          'Descargar todas las transacciones',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _exportCSV,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
