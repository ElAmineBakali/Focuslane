import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:focuslane/design/blocks/toast/app_toast.dart';
import 'package:focuslane/design/ui/focuslane_ui.dart';
import 'package:focuslane/navigation/app_routes.dart';
import 'package:focuslane/screens/auth/widgets/auth_form_card.dart';
import 'package:focuslane/screens/auth/widgets/auth_header.dart';
import 'package:focuslane/screens/auth/widgets/auth_primary_button.dart';
import 'package:focuslane/screens/auth/widgets/auth_secondary_link.dart';
import 'package:focuslane/screens/auth/widgets/auth_shell.dart';
import 'package:focuslane/screens/auth/widgets/auth_text_field.dart';

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
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _signin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await fb_auth.FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _pass.text,
      );
      TextInput.finishAutofillContext();
    } on fb_auth.FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = _authError(e));
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'No se pudo iniciar sesión. Inténtalo de nuevo.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _google() async {
    FocusScope.of(context).unfocus();
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
        setState(
          () =>
              _error =
                  'El acceso con Google no está configurado en esta plataforma.',
        );
      }
    } on fb_auth.FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = _authError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(
        () =>
            _error =
                'Escribe tu correo electrónico para recuperar la contraseña.',
      );
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await fb_auth.FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      AppToast.success(
        context,
        'Te hemos enviado un correo para restablecer la contraseña.',
      );
    } on fb_auth.FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = _authError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final compact = FocuslaneTokens.isCompact(context);

    return AuthShell(
      child: Column(
        children: [
          const AuthHeader(
            title: 'Bienvenido de nuevo',
            subtitle: 'Accede a tu espacio de productividad con tu cuenta.',
          ),
          SizedBox(height: compact ? 14 : 24),
          AuthFormCard(
            child: AutofillGroup(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AuthTextField(
                      label: 'Correo electrónico',
                      hint: 'correo@empresa.com',
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.alternate_email_rounded,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        final v = (value ?? '').trim();
                        if (v.isEmpty) return 'El correo es obligatorio';
                        if (!v.contains('@')) {
                          return 'Introduce un correo válido';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: compact ? 12 : 14),
                    AuthTextField(
                      label: 'Contraseña',
                      hint: 'Mínimo 6 caracteres',
                      controller: _pass,
                      obscureText: _obscurePassword,
                      prefixIcon: Icons.lock_outline_rounded,
                      suffixIcon: IconButton(
                        tooltip:
                            _obscurePassword
                                ? 'Mostrar contraseña'
                                : 'Ocultar contraseña',
                        onPressed:
                            () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                      autofillHints: const [AutofillHints.password],
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) {
                        if (!_busy) _signin();
                      },
                      validator: (value) {
                        final v = value ?? '';
                        if (v.length < 6) {
                          return 'La contraseña debe tener al menos 6 caracteres';
                        }
                        return null;
                      },
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _busy ? null : _resetPassword,
                        child: const Text('¿Olvidaste la contraseña?'),
                      ),
                    ),
                    if (_error != null) ...[
                      _AuthMessage(message: _error!, isError: true),
                      SizedBox(height: compact ? 10 : 12),
                    ],
                    AuthPrimaryButton(
                      label: 'Iniciar sesión',
                      icon: Icons.login_rounded,
                      isLoading: _busy,
                      onPressed: _busy ? null : _signin,
                    ),
                    SizedBox(height: compact ? 12 : 14),
                    Row(
                      children: [
                        Expanded(child: Divider(color: scheme.outlineVariant)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            'o continúa con',
                            style: Theme.of(
                              context,
                            ).textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: scheme.outlineVariant)),
                      ],
                    ),
                    SizedBox(height: compact ? 12 : 14),
                    FocusSecondaryButton(
                      label: 'Google',
                      icon: Icons.g_mobiledata_rounded,
                      fullWidth: true,
                      onPressed: _busy ? null : _google,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: compact ? 14 : 18),
          AuthSecondaryLink(
            label: '¿No tienes cuenta? ',
            actionLabel: 'Crear cuenta',
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.register),
          ),
        ],
      ),
    );
  }
}

class _AuthMessage extends StatelessWidget {
  const _AuthMessage({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = isError ? scheme.errorContainer : scheme.secondaryContainer;
    final fg = isError ? scheme.onErrorContainer : scheme.onSecondaryContainer;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError
                ? Icons.error_outline_rounded
                : Icons.check_circle_outline_rounded,
            color: fg,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: fg,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _authError(fb_auth.FirebaseAuthException e) {
  switch (e.code) {
    case 'invalid-email':
      return 'El correo electrónico no tiene un formato válido.';
    case 'user-disabled':
      return 'Esta cuenta está desactivada.';
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return 'El correo o la contraseña no son correctos.';
    case 'too-many-requests':
      return 'Demasiados intentos. Espera un momento antes de volver a probar.';
    case 'network-request-failed':
      return 'No hay conexión suficiente para iniciar sesión.';
    case 'popup-closed-by-user':
      return 'Se cerró la ventana de Google antes de completar el acceso.';
    default:
      return 'No se pudo iniciar sesión. Inténtalo de nuevo.';
  }
}
