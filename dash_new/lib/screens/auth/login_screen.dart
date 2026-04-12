import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:focuslane/core/constants/app_strings.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _signin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await fb_auth.FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _pass.text,
      );
    } on fb_auth.FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = e.message ?? e.code);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _google() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (kIsWeb) {
        await fb_auth.FirebaseAuth.instance.signInWithPopup(
          fb_auth.GoogleAuthProvider(),
        );
      } else {
        setState(() => _error = AppStrings.authGoogleNoNativo);
      }
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
              margin: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF2B3548), width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0A0F18), Color(0xFF0B1220)],
                    ),
                  ),
                    child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(isMobile ? 16 : 24, isMobile ? 12 : 24, isMobile ? 16 : 24, isMobile ? 6 : 24),
                      child: Form(
                        key: _formKey,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Column(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2A3240),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.token_outlined, color: Color(0xFF84C8C1)),
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'Bienvenido a FocusLane',
                                style: TextStyle(
                                  color: Color(0xFF84C8C1),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 30,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                AppStrings.authSubtituloLogin,
                                style: TextStyle(color: Color(0xFF8E98AA), fontSize: 15),
                              ),
                              SizedBox(height: isMobile ? 16 : 20),
                              Container(
                                padding: EdgeInsets.all(isMobile ? 14 : 20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF353743),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    _label(AppStrings.authCorreo),
                                    _field(
                                      controller: _email,
                                      hint: AppStrings.hintCorreo,
                                      validator: (value) {
                                        final v = (value ?? '').trim();
                                        if (v.isEmpty) return AppStrings.validacionRequerido;
                                        if (!v.contains('@')) return AppStrings.validacionCorreoInvalido;
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 14),
                                    Row(
                                      children: const [
                                        _LabelText(AppStrings.authContrasena),
                                        Spacer(),
                                        Text(
                                          AppStrings.authOlvidoContrasena,
                                          style: TextStyle(
                                            color: Color(0xFF84C8C1),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    _field(
                                      controller: _pass,
                                      hint: '••••••••',
                                      obscureText: true,
                                      validator: (value) {
                                        final v = value ?? '';
                                        if (v.length < 6) return AppStrings.validacionMin6;
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 14),
                                    SizedBox(
                                      width: double.infinity,
                                      child: FilledButton(
                                        onPressed: _busy ? null : _signin,
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
                                                AppStrings.authIniciarSesion,
                                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    const Text(
                                      AppStrings.authOContinuarCon,
                                      style: TextStyle(color: Color(0xFF70798A), fontSize: 11, letterSpacing: 1.1),
                                    ),
                                    const SizedBox(height: 10),
                                    if (isMobile)
                                      Column(
                                        children: [
                                          _socialButton(
                                            context,
                                            label: 'Google',
                                            icon: Icons.g_mobiledata,
                                            onPressed: _busy ? null : _google,
                                          ),
                                          const SizedBox(height: 10),
                                          _socialButton(
                                            context,
                                            label: 'SSO',
                                            icon: Icons.badge_outlined,
                                            onPressed: null,
                                          ),
                                        ],
                                      )
                                    else
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _socialButton(
                                              context,
                                              label: 'Google',
                                              icon: Icons.g_mobiledata,
                                              onPressed: _busy ? null : _google,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: _socialButton(
                                              context,
                                              label: 'SSO',
                                              icon: Icons.badge_outlined,
                                              onPressed: null,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                              if (_error != null) ...[
                                const SizedBox(height: 10),
                                Text(_error!, style: const TextStyle(color: Color(0xFFF44336))),
                              ],
                              const SizedBox(height: 12),
                              Wrap(
                                alignment: WrapAlignment.center,
                                children: [
                                  const Text(AppStrings.authNoTienesCuenta, style: TextStyle(color: Color(0xFF8E98AA))),
                                  InkWell(
                                    onTap: () => Navigator.of(context).pushNamed('/register'),
                                    child: const Text(
                                      AppStrings.authRegistrarseAhora,
                                      style: TextStyle(color: Color(0xFF84C8C1), fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
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
    return Align(
      alignment: Alignment.centerLeft,
      child: _LabelText(text),
    );
  }

  Widget _socialButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: const BorderSide(color: Color(0xFF434C5F)),
        ),
        icon: Icon(icon, size: 18, color: const Color(0xFF9AA3B3)),
        label: Text(label, style: const TextStyle(color: Color(0xFFD2D7E1))),
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
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF414C5F)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF84C8C1)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFF44336)),
        ),
      ),
    );
  }
}

class _LabelText extends StatelessWidget {
  const _LabelText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
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
}

