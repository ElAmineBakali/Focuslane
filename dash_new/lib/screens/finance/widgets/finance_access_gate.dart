import 'package:flutter/material.dart';

import 'package:focuslane/design/ui/focuslane_ui.dart';
import 'package:focuslane/navigation/app_routes.dart';
import 'package:focuslane/screens/finance/services/finance_security_service.dart';

class FinanceAccessGate extends StatefulWidget {
  const FinanceAccessGate({super.key, required this.child});

  final Widget child;

  @override
  State<FinanceAccessGate> createState() => _FinanceAccessGateState();
}

class _FinanceAccessGateState extends State<FinanceAccessGate> {
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmCtrl = TextEditingController();
  final TextEditingController _unlockCtrl = TextEditingController();

  bool _loading = true;
  bool _hasPassword = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _unlockCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    if (FinanceSecurityService.I.isSessionUnlocked) {
      if (mounted) {
        setState(() {
          _loading = false;
          _hasPassword = true;
        });
      }
      return;
    }

    final hasPassword = await FinanceSecurityService.I.hasPassword();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _hasPassword = hasPassword;
    });
  }

  Future<void> _createPassword() async {
    if (_busy) return;

    final password = _passwordCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (password.length < 6) {
      setState(
        () => _error = 'La contraseña debe tener al menos 6 caracteres.',
      );
      return;
    }
    if (password != confirm) {
      setState(() => _error = 'Las contraseñas no coinciden.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    await FinanceSecurityService.I.setPassword(password);

    if (!mounted) return;
    setState(() {
      _busy = false;
      _hasPassword = true;
      _passwordCtrl.clear();
      _confirmCtrl.clear();
    });
  }

  Future<void> _unlock() async {
    if (_busy) return;
    final password = _unlockCtrl.text.trim();
    if (password.isEmpty) {
      setState(() => _error = 'Introduce la contraseña.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final ok = await FinanceSecurityService.I.verifyAndUnlock(password);

    if (!mounted) return;
    if (!ok) {
      setState(() {
        _busy = false;
        _error = 'Contraseña incorrecta.';
      });
      return;
    }

    setState(() {
      _busy = false;
      _unlockCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (FinanceSecurityService.I.isSessionUnlocked) {
      return widget.child;
    }

    return AppShell(
      title: 'Finanzas',
      subtitle: 'Acceso protegido.',
      activeRoute: AppRoutes.financeDashboard,
      child:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: PageContainer(
                  maxWidth: 760,
                  child: _AccessCard(
                    hasPassword: _hasPassword,
                    busy: _busy,
                    error: _error,
                    passwordCtrl: _passwordCtrl,
                    confirmCtrl: _confirmCtrl,
                    unlockCtrl: _unlockCtrl,
                    onCreatePassword: _createPassword,
                    onUnlock: _unlock,
                  ),
                ),
              ),
    );
  }
}

class _AccessCard extends StatelessWidget {
  const _AccessCard({
    required this.hasPassword,
    required this.busy,
    required this.error,
    required this.passwordCtrl,
    required this.confirmCtrl,
    required this.unlockCtrl,
    required this.onCreatePassword,
    required this.onUnlock,
  });

  final bool hasPassword;
  final bool busy;
  final String? error;
  final TextEditingController passwordCtrl;
  final TextEditingController confirmCtrl;
  final TextEditingController unlockCtrl;
  final VoidCallback onCreatePassword;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FocusCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.lock_outline_rounded, color: scheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasPassword
                          ? 'Desbloquear Finanzas'
                          : 'Proteger Finanzas',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      hasPassword
                          ? 'Introduce la contraseña del módulo para continuar.'
                          : 'Crea una contraseña local para proteger el módulo financiero.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (hasPassword)
            FocusTextField(
              controller: unlockCtrl,
              label: 'Contrasena de finanzas',
              prefixIcon: Icons.lock_rounded,
              obscureText: true,
              onChanged: (_) {},
            )
          else ...[
            FocusTextField(
              controller: passwordCtrl,
              label: 'Nueva contraseña',
              prefixIcon: Icons.lock_reset_rounded,
              obscureText: true,
            ),
            const SizedBox(height: 12),
            FocusTextField(
              controller: confirmCtrl,
              label: 'Confirmar contraseña',
              prefixIcon: Icons.verified_user_outlined,
              obscureText: true,
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: 12),
            _AccessError(message: error!),
          ],
          const SizedBox(height: 18),
          FocusPrimaryButton(
            label:
                busy
                    ? (hasPassword ? 'Verificando...' : 'Guardando...')
                    : (hasPassword ? 'Entrar' : 'Crear contraseña'),
            icon: hasPassword ? Icons.login_rounded : Icons.lock_rounded,
            fullWidth: true,
            isLoading: busy,
            onPressed:
                busy ? null : (hasPassword ? onUnlock : onCreatePassword),
          ),
        ],
      ),
    );
  }
}

class _AccessError extends StatelessWidget {
  const _AccessError({required this.message});

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
