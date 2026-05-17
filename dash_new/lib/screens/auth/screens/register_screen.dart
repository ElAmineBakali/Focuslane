import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:focuslane/navigation/app_routes.dart';
import 'package:focuslane/screens/auth/widgets/auth_form_card.dart';
import 'package:focuslane/screens/auth/widgets/auth_header.dart';
import 'package:focuslane/screens/auth/widgets/auth_primary_button.dart';
import 'package:focuslane/screens/auth/widgets/auth_secondary_link.dart';
import 'package:focuslane/screens/auth/widgets/auth_shell.dart';
import 'package:focuslane/screens/auth/widgets/auth_text_field.dart';

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
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
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
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final credential = await fb_auth.FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _email.text.trim(),
            password: _pass.text,
          );
      final displayName = _name.text.trim();
      if (displayName.isNotEmpty) {
        await credential.user?.updateDisplayName(displayName);
      }
      TextInput.finishAutofillContext();
      if (mounted) Navigator.of(context).pop();
    } on fb_auth.FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = _authError(e));
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'No se pudo crear la cuenta. Inténtalo de nuevo.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 560;

    return AuthShell(
      maxWidth: 520,
      child: Column(
        children: [
          const AuthHeader(
            title: 'Crea tu cuenta',
            subtitle:
                'Prepara tu espacio para tareas, notas, calendario y hábitos.',
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
                      label: 'Nombre completo',
                      hint: 'Escribe tu nombre',
                      controller: _name,
                      prefixIcon: Icons.person_outline_rounded,
                      autofillHints: const [AutofillHints.name],
                      textInputAction: TextInputAction.next,
                      validator:
                          (value) =>
                              (value == null || value.trim().isEmpty)
                                  ? 'El nombre es obligatorio'
                                  : null,
                    ),
                    SizedBox(height: compact ? 12 : 14),
                    AuthTextField(
                      label: 'Correo electrónico',
                      hint: 'correo@empresa.com',
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.alternate_email_rounded,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        final s = (value ?? '').trim();
                        if (s.isEmpty) return 'El correo es obligatorio';
                        if (!s.contains('@')) {
                          return 'Introduce un correo válido';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: compact ? 12 : 14),
                    if (compact)
                      Column(
                        children: [
                          _PasswordField(
                            label: 'Contraseña',
                            controller: _pass,
                            obscureText: _obscurePassword,
                            onToggle:
                                () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                            validator:
                                (value) =>
                                    (value == null || value.length < 6)
                                        ? 'Mínimo 6 caracteres'
                                        : null,
                          ),
                          SizedBox(height: compact ? 12 : 14),
                          _PasswordField(
                            label: 'Confirmar contraseña',
                            controller: _confirm,
                            obscureText: _obscureConfirm,
                            onToggle:
                                () => setState(
                                  () => _obscureConfirm = !_obscureConfirm,
                                ),
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) {
                              if (!_busy) _register();
                            },
                            validator:
                                (value) =>
                                    value != _pass.text
                                        ? 'Las contraseñas no coinciden'
                                        : null,
                          ),
                        ],
                      )
                    else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _PasswordField(
                              label: 'Contraseña',
                              controller: _pass,
                              obscureText: _obscurePassword,
                              onToggle:
                                  () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                              validator:
                                  (value) =>
                                      (value == null || value.length < 6)
                                          ? 'Mínimo 6 caracteres'
                                          : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _PasswordField(
                              label: 'Confirmar',
                              controller: _confirm,
                              obscureText: _obscureConfirm,
                              onToggle:
                                  () => setState(
                                    () => _obscureConfirm = !_obscureConfirm,
                                  ),
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) {
                                if (!_busy) _register();
                              },
                              validator:
                                  (value) =>
                                      value != _pass.text
                                          ? 'No coincide'
                                          : null,
                            ),
                          ),
                        ],
                      ),
                    if (_error != null) ...[
                      SizedBox(height: compact ? 12 : 14),
                      _AuthMessage(message: _error!),
                    ],
                    SizedBox(height: compact ? 14 : 18),
                    AuthPrimaryButton(
                      label: 'Crear cuenta',
                      icon: Icons.person_add_alt_rounded,
                      isLoading: _busy,
                      onPressed: _busy ? null : _register,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: compact ? 14 : 18),
          AuthSecondaryLink(
            label: '¿Ya tienes una cuenta? ',
            actionLabel: 'Iniciar sesión',
            onTap:
                () =>
                    Navigator.of(context).canPop()
                        ? Navigator.of(context).pop()
                        : Navigator.of(
                          context,
                        ).pushReplacementNamed(AppRoutes.login),
          ),
        ],
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.label,
    required this.controller,
    required this.obscureText,
    required this.onToggle,
    required this.validator,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final bool obscureText;
  final VoidCallback onToggle;
  final String? Function(String?) validator;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return AuthTextField(
      label: label,
      hint: 'Mínimo 6 caracteres',
      controller: controller,
      obscureText: obscureText,
      prefixIcon: Icons.lock_outline_rounded,
      suffixIcon: IconButton(
        tooltip: obscureText ? 'Mostrar contraseña' : 'Ocultar contraseña',
        onPressed: onToggle,
        icon: Icon(
          obscureText
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
        ),
      ),
      autofillHints: const [AutofillHints.newPassword],
      textInputAction: textInputAction ?? TextInputAction.next,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
    );
  }
}

class _AuthMessage extends StatelessWidget {
  const _AuthMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: scheme.onErrorContainer,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onErrorContainer,
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
    case 'email-already-in-use':
      return 'Ya existe una cuenta con este correo electrónico.';
    case 'invalid-email':
      return 'El correo electrónico no tiene un formato válido.';
    case 'weak-password':
      return 'La contraseña es demasiado débil.';
    case 'operation-not-allowed':
      return 'El registro con correo y contraseña no está habilitado.';
    case 'network-request-failed':
      return 'No hay conexión suficiente para crear la cuenta.';
    default:
      return 'No se pudo crear la cuenta. Inténtalo de nuevo.';
  }
}
