import 'package:flutter/material.dart';

import '../../../../design/ui/components/focus_card.dart';
import '../../../../design/ui/components/focus_module_header.dart';
import '../../../../design/ui/tokens/focuslane_tokens.dart';
import '../../services/finance_security_service.dart';

class FinanceSettingsScreen extends StatefulWidget {
  const FinanceSettingsScreen({
    super.key,
    required this.onBackToDashboard,
  });

  final VoidCallback onBackToDashboard;

  static const route = '/finance/settings';

  @override
  State<FinanceSettingsScreen> createState() => _FinanceSettingsScreenState();
}

class _FinanceSettingsScreenState extends State<FinanceSettingsScreen> {
  final TextEditingController _currentPasswordCtrl = TextEditingController();
  final TextEditingController _newPasswordCtrl = TextEditingController();
  final TextEditingController _confirmPasswordCtrl = TextEditingController();

  bool _busy = false;
  bool _hasPassword = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  @override
  void dispose() {
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadState() async {
    final hasPassword = await FinanceSecurityService.I.hasPassword();
    if (!mounted) return;
    setState(() => _hasPassword = hasPassword);
  }

  Future<void> _savePassword() async {
    if (_busy) return;

    final currentPassword = _currentPasswordCtrl.text.trim();
    final newPassword = _newPasswordCtrl.text.trim();
    final confirmPassword = _confirmPasswordCtrl.text.trim();

    if (newPassword.length < 6) {
      setState(() => _error = 'La contraseña debe tener al menos 6 caracteres.');
      return;
    }
    if (newPassword != confirmPassword) {
      setState(() => _error = 'La nueva contraseña y la confirmación no coinciden.');
      return;
    }
    if (_hasPassword && currentPassword.isEmpty) {
      setState(() => _error = 'Introduce la contraseña actual.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final changed = await FinanceSecurityService.I.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );

    if (!mounted) return;
    if (!changed) {
      setState(() {
        _busy = false;
        _error = 'La contraseña actual es incorrecta.';
      });
      return;
    }

    await _loadState();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _currentPasswordCtrl.clear();
      _newPasswordCtrl.clear();
      _confirmPasswordCtrl.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _hasPassword
              ? 'Contraseña de finanzas actualizada.'
              : 'Contraseña de finanzas creada.',
        ),
      ),
    );
  }

  Future<void> _lockNow() async {
    await FinanceSecurityService.I.clearSession();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Módulo de finanzas bloqueado.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: FocusModuleHeader(
        title: 'Finanzas',
        subtitle: 'Ajustes',
        leadingMode: FocusModuleLeadingMode.backToModuleDashboard,
        onBack: widget.onBackToDashboard,
      ),
      body: SingleChildScrollView(
        padding: FocuslaneTokens.pagePaddingCompact,
        child: Column(
          children: [
            FocusCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _hasPassword
                        ? 'Cambiar contraseña de finanzas'
                        : 'Crear contraseña de finanzas',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Esta contraseña protege el acceso al módulo completo de finanzas.',
                  ),
                  const SizedBox(height: 14),
                  if (_hasPassword) ...[
                    TextField(
                      controller: _currentPasswordCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña actual',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  TextField(
                    controller: _newPasswordCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Nueva contraseña',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _confirmPasswordCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirmar nueva contraseña',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _busy ? null : _savePassword,
                      child: Text(_busy ? 'Guardando...' : 'Guardar contraseña'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FocusCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bloqueo',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Cierra la sesión actual del módulo para volver a pedir contraseña.',
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _lockNow,
                      child: const Text('Bloquear finanzas ahora'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}



