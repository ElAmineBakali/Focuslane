import 'package:flutter/material.dart';

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
      setState(() => _error = 'La contraseÃ±a debe tener al menos 6 caracteres.');
      return;
    }
    if (password != confirm) {
      setState(() => _error = 'Las contraseÃ±as no coinciden.');
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
      setState(() => _error = 'Introduce la contraseÃ±a.');
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
        _error = 'ContraseÃ±a incorrecta.';
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
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (FinanceSecurityService.I.isSessionUnlocked) {
      return widget.child;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Acceso protegido a finanzas')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _hasPassword ? _buildUnlockView() : _buildSetupView(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSetupView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Crea una contraseÃ±a para proteger el mÃ³dulo de finanzas.',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordCtrl,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Nueva contraseÃ±a',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _confirmCtrl,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Confirmar contraseÃ±a',
            border: OutlineInputBorder(),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!, style: const TextStyle(color: Colors.red)),
        ],
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _busy ? null : _createPassword,
            child: Text(_busy ? 'Guardando...' : 'Crear contraseÃ±a'),
          ),
        ),
      ],
    );
  }

  Widget _buildUnlockView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Introduce la contraseÃ±a de finanzas para continuar.',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _unlockCtrl,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'ContraseÃ±a de finanzas',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _unlock(),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!, style: const TextStyle(color: Colors.red)),
        ],
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _busy ? null : _unlock,
            child: Text(_busy ? 'Verificando...' : 'Entrar'),
          ),
        ),
      ],
    );
  }
}

