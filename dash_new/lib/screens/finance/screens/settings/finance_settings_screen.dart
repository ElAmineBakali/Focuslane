import 'package:flutter/material.dart';

import 'package:focuslane/design/ui/focuslane_ui.dart';
import 'package:focuslane/screens/finance/services/finance_security_service.dart';

class FinanceSettingsScreen extends StatefulWidget {
  const FinanceSettingsScreen({super.key, required this.onBackToDashboard});

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
      setState(
        () => _error = 'La contraseña debe tener al menos 6 caracteres.',
      );
      return;
    }
    if (newPassword != confirmPassword) {
      setState(
        () => _error = 'La nueva contraseña y la confirmación no coinciden.',
      );
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
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      child: PageContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FocusCard(
              child: FocusSectionHeader(
                title: 'Ajustes de Finanzas',
                subtitle: 'Seguridad y bloqueo del módulo protegido',
                icon: Icons.lock_outline_rounded,
                trailing: FocusBadge(
                  label: _hasPassword ? 'Protegido' : 'Pendiente',
                  color: _hasPassword ? scheme.primary : scheme.error,
                ),
              ),
            ),
            const SizedBox(height: 16),
            FocusCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _hasPassword
                        ? 'Cambiar contraseña de finanzas'
                        : 'Crear contraseña de finanzas',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Esta contraseña protege el acceso al módulo completo de finanzas.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_hasPassword) ...[
                    FocusTextField(
                      controller: _currentPasswordCtrl,
                      label: 'Contraseña actual',
                      prefixIcon: Icons.lock_outline_rounded,
                      obscureText: true,
                    ),
                    const SizedBox(height: 12),
                  ],
                  FocusTextField(
                    controller: _newPasswordCtrl,
                    label: 'Nueva contraseña',
                    prefixIcon: Icons.lock_reset_rounded,
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  FocusTextField(
                    controller: _confirmPasswordCtrl,
                    label: 'Confirmar nueva contraseña',
                    prefixIcon: Icons.verified_user_outlined,
                    obscureText: true,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    _ErrorMessage(message: _error!),
                  ],
                  const SizedBox(height: 16),
                  FocusPrimaryButton(
                    label: _busy ? 'Guardando...' : 'Guardar contraseña',
                    icon: Icons.save_outlined,
                    fullWidth: true,
                    isLoading: _busy,
                    onPressed: _busy ? null : _savePassword,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FocusCard(
              elevated: false,
              backgroundColor: scheme.surfaceContainerLow,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FocusSectionHeader(
                    title: 'Bloqueo',
                    subtitle: 'Cierra la sesión actual del módulo protegido',
                    icon: Icons.logout_rounded,
                  ),
                  const SizedBox(height: 16),
                  FocusSecondaryButton(
                    label: 'Bloquear finanzas ahora',
                    icon: Icons.lock_rounded,
                    fullWidth: true,
                    onPressed: _lockNow,
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

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.error.withValues(alpha: 0.28)),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: scheme.error,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
