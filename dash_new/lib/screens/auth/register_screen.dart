import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/core/constants/app_strings.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await fb_auth.FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _pass.text,
      );
      if (mounted) Navigator.of(context).pop();
    } on fb_auth.FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = e.message ?? e.code);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 760;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F18),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 16, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF2B3548), width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  color: const Color(0xFF0A0F18),
                  child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(isMobile ? 16 : 24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 430),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              const SizedBox(height: 6),
                              const Text(
                                'EL AMINE',
                                style: TextStyle(
                                  color: Color(0xFF84C8C1),
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                AppStrings.portalProductividad,
                                style: TextStyle(color: Color(0xFF8691A4), fontSize: 14),
                              ),
                              SizedBox(height: isMobile ? 12 : 16),
                              Container(
                                padding: EdgeInsets.all(isMobile ? 14 : 20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF353743),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      AppStrings.authCrearCuenta,
                                      style: TextStyle(
                                        color: Color(0xFFE3E2E9),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 38,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      AppStrings.authSubtituloRegistro,
                                      style: TextStyle(color: Color(0xFFA7AFBE), fontSize: 14),
                                    ),
                                    const SizedBox(height: 14),
                                    _label(AppStrings.authNombreCompleto),
                                    _field(
                                      controller: _name,
                                      hint: AppStrings.hintNombre,
                                      validator: (v) => (v == null || v.trim().isEmpty) ? AppStrings.validacionRequerido : null,
                                    ),
                                    const SizedBox(height: 12),
                                    _label(AppStrings.authCorreo),
                                    _field(
                                      controller: _email,
                                      hint: AppStrings.hintCorreo,
                                      validator: (v) {
                                        final s = (v ?? '').trim();
                                        if (s.isEmpty) return AppStrings.validacionRequerido;
                                        if (!s.contains('@')) return AppStrings.validacionCorreoInvalido;
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    if (isMobile)
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _label(AppStrings.authContrasena),
                                          _field(
                                            controller: _pass,
                                            hint: '••••••••',
                                            obscureText: true,
                                            validator: (v) => (v == null || v.length < 6) ? AppStrings.validacionMin6 : null,
                                          ),
                                          const SizedBox(height: 12),
                                          _label(AppStrings.authConfirmar),
                                          _field(
                                            controller: _confirm,
                                            hint: '••••••••',
                                            obscureText: true,
                                            validator: (v) => v != _pass.text ? AppStrings.validacionNoCoincide : null,
                                          ),
                                        ],
                                      )
                                    else
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                _label(AppStrings.authContrasena),
                                                _field(
                                                  controller: _pass,
                                                  hint: '••••••••',
                                                  obscureText: true,
                                                  validator: (v) =>
                                                      (v == null || v.length < 6) ? AppStrings.validacionMin6 : null,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                _label(AppStrings.authConfirmar),
                                                _field(
                                                  controller: _confirm,
                                                  hint: '••••••••',
                                                  obscureText: true,
                                                  validator: (v) => v != _pass.text ? AppStrings.validacionNoCoincide : null,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    const SizedBox(height: 14),
                                    SizedBox(
                                      width: double.infinity,
                                      child: FilledButton(
                                        onPressed: _busy ? null : _register,
                                        style: FilledButton.styleFrom(
                                          backgroundColor: const Color(0xFF70B0AB),
                                          foregroundColor: const Color(0xFF10211F),
                                          padding: const EdgeInsets.symmetric(vertical: 13),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        child: _busy
                                            ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              )
                                            : const Text(
                                                AppStrings.authBotonCrearCuenta,
                                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                              ),
                                      ),
                                    ),
                                    if (_error != null) ...[
                                      const SizedBox(height: 10),
                                      Text(_error!, style: const TextStyle(color: Color(0xFFF44336))),
                                    ],
                                    const SizedBox(height: 18),
                                    Wrap(
                                      alignment: WrapAlignment.center,
                                      children: [
                                        const Text(
                                          AppStrings.authYaTienesCuenta,
                                          style: TextStyle(color: Color(0xFFA7AFBE)),
                                        ),
                                        InkWell(
                                          onTap: () => Navigator.of(context).pop(),
                                          child: const Text(
                                            AppStrings.authEntrar,
                                            style: TextStyle(
                                              color: Color(0xFF84C8C1),
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'SECURE      ENCRYPTED',
                                style: TextStyle(color: Color(0xFF6D778A), fontSize: 11, letterSpacing: 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFFA9B0BF),
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(color: Color(0xFFE3E2E9)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF6D778A)),
        filled: true,
        fillColor: const Color(0xFF121826),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF414C5F)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF84C8C1)),
        ),
      ),
    );
  }
}
