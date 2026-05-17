import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:focuslane/core/services/module_visibility_service.dart';
import 'package:focuslane/design/blocks/toast/app_toast.dart';
import 'package:focuslane/design/ui/focuslane_ui.dart';
import 'package:focuslane/navigation/app_routes.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    this.currentThemeMode,
    this.onThemeModeChanged,
  });

  final ThemeMode? currentThemeMode;
  final ValueChanged<ThemeMode>? onThemeModeChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  final ModuleVisibilityService _visibility = ModuleVisibilityService.instance;

  bool _loadingProfile = true;
  bool _savingProfile = false;
  bool _changingPassword = false;
  bool _signingOut = false;

  String _displayName = '';
  String _photoUrl = '';
  late ThemeMode _selectedThemeMode;

  @override
  void initState() {
    super.initState();
    _selectedThemeMode = widget.currentThemeMode ?? ThemeMode.system;
    _loadUserProfile();
    _visibility.ensureLoaded().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _loadingProfile = false);
      return;
    }

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('profile')
              .doc('info')
              .get();
      final data = doc.data() ?? const <String, dynamic>{};

      _displayName =
          ((data['displayName'] as String?) ?? user.displayName ?? '').trim();
      _photoUrl = ((data['photoUrl'] as String?) ?? user.photoURL ?? '').trim();
      _nameController.text = _displayName;
      _bioController.text = (data['bio'] as String? ?? '').trim();
    } catch (_) {
      _displayName = user.displayName?.trim() ?? '';
      _photoUrl = user.photoURL?.trim() ?? '';
      _nameController.text = _displayName;
    } finally {
      if (mounted) {
        setState(() => _loadingProfile = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _savingProfile) return;

    setState(() => _savingProfile = true);
    final displayName = _nameController.text.trim();
    final bio = _bioController.text.trim();

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('profile')
          .doc('info')
          .set({
            'displayName': displayName,
            'bio': bio,
            'photoUrl': _photoUrl,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      if (displayName.isNotEmpty && displayName != user.displayName) {
        await user.updateDisplayName(displayName);
      }
      if (_photoUrl.isNotEmpty && _photoUrl != user.photoURL) {
        await user.updatePhotoURL(_photoUrl);
      }

      setState(() {
        _displayName = displayName;
      });

      if (!mounted) return;
      AppToast.success(context, 'Perfil actualizado.');
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, 'No se pudo guardar el perfil: $e');
    } finally {
      if (mounted) {
        setState(() => _savingProfile = false);
      }
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 84,
        maxWidth: 1200,
      );
      if (file == null) return;

      final ref = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(user.uid)
          .child('profile.jpg');

      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      } else {
        await ref.putFile(
          File(file.path),
          SettableMetadata(contentType: 'image/jpeg'),
        );
      }

      final url = await ref.getDownloadURL();
      setState(() => _photoUrl = url);
      await _saveProfile();
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, 'No se pudo actualizar la foto: $e');
    }
  }

  Future<void> _changePassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _changingPassword) return;

    final pass = _passwordController.text;
    final confirm = _passwordConfirmController.text;
    if (pass.length < 6) {
      AppToast.warning(
        context,
        'La contraseña debe tener al menos 6 caracteres.',
      );
      return;
    }
    if (pass != confirm) {
      AppToast.warning(context, 'Las contraseñas no coinciden.');
      return;
    }

    setState(() => _changingPassword = true);
    try {
      await user.updatePassword(pass);
      _passwordController.clear();
      _passwordConfirmController.clear();
      if (!mounted) return;
      AppToast.success(context, 'Contraseña actualizada.');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final msg =
          e.code == 'requires-recent-login'
              ? 'Por seguridad, vuelve a iniciar sesión y prueba de nuevo.'
              : 'No se pudo cambiar la contraseña.';
      AppToast.error(context, msg);
    } finally {
      if (mounted) {
        setState(() => _changingPassword = false);
      }
    }
  }

  Future<void> _signOut() async {
    if (_signingOut) return;
    setState(() => _signingOut = true);
    try {
      await FirebaseAuth.instance.signOut();
    } finally {
      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
      }
    }
  }

  Future<void> _toggleModule(String route, bool enabled) async {
    await _visibility.setEnabled(route, enabled);
    if (!mounted) return;
    setState(() {});
    AppToast.info(
      context,
      enabled
          ? 'Módulo visible en la navegación.'
          : 'Módulo oculto en la navegación.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Ajustes',
      subtitle: 'Cuenta, tema, módulos y preferencias generales.',
      activeRoute: AppRoutes.settings,
      child:
          _loadingProfile
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: PageContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SettingsHero(
                        displayName: _displayName,
                        email: FirebaseAuth.instance.currentUser?.email ?? '',
                      ),
                      SizedBox(height: FocuslaneTokens.pageGapFor(context)),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final twoColumns = constraints.maxWidth >= 980;
                          if (!twoColumns) {
                            return Column(
                              children: [
                                _ProfileCard(
                                  displayName: _displayName,
                                  photoUrl: _photoUrl,
                                  nameController: _nameController,
                                  bioController: _bioController,
                                  saving: _savingProfile,
                                  onPickPhoto: _pickAndUploadPhoto,
                                  onSave: _saveProfile,
                                ),
                                SizedBox(
                                  height: FocuslaneTokens.pageGapFor(context),
                                ),
                                _AppearanceCard(
                                  selectedThemeMode: _selectedThemeMode,
                                  onChanged: _setThemeMode,
                                ),
                                SizedBox(
                                  height: FocuslaneTokens.pageGapFor(context),
                                ),
                                _ModulesCard(
                                  visibility: _visibility,
                                  onChanged: _toggleModule,
                                ),
                                SizedBox(
                                  height: FocuslaneTokens.pageGapFor(context),
                                ),
                                _NotificationAccessCard(
                                  onOpen:
                                      () => Navigator.of(
                                        context,
                                      ).pushNamed(AppRoutes.notifications),
                                ),
                                SizedBox(
                                  height: FocuslaneTokens.pageGapFor(context),
                                ),
                                _SecurityCard(
                                  passwordController: _passwordController,
                                  passwordConfirmController:
                                      _passwordConfirmController,
                                  changingPassword: _changingPassword,
                                  onChangePassword: _changePassword,
                                ),
                                SizedBox(
                                  height: FocuslaneTokens.pageGapFor(context),
                                ),
                                _SignOutCard(
                                  signingOut: _signingOut,
                                  onSignOut: _signOut,
                                ),
                              ],
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 7,
                                child: Column(
                                  children: [
                                    _ProfileCard(
                                      displayName: _displayName,
                                      photoUrl: _photoUrl,
                                      nameController: _nameController,
                                      bioController: _bioController,
                                      saving: _savingProfile,
                                      onPickPhoto: _pickAndUploadPhoto,
                                      onSave: _saveProfile,
                                    ),
                                    SizedBox(
                                      height: FocuslaneTokens.pageGapFor(
                                        context,
                                      ),
                                    ),
                                    _ModulesCard(
                                      visibility: _visibility,
                                      onChanged: _toggleModule,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                flex: 5,
                                child: Column(
                                  children: [
                                    _AppearanceCard(
                                      selectedThemeMode: _selectedThemeMode,
                                      onChanged: _setThemeMode,
                                    ),
                                    SizedBox(
                                      height: FocuslaneTokens.pageGapFor(
                                        context,
                                      ),
                                    ),
                                    _NotificationAccessCard(
                                      onOpen:
                                          () => Navigator.of(
                                            context,
                                          ).pushNamed(AppRoutes.notifications),
                                    ),
                                    const SizedBox(height: 16),
                                    _SecurityCard(
                                      passwordController: _passwordController,
                                      passwordConfirmController:
                                          _passwordConfirmController,
                                      changingPassword: _changingPassword,
                                      onChangePassword: _changePassword,
                                    ),
                                    const SizedBox(height: 16),
                                    _SignOutCard(
                                      signingOut: _signingOut,
                                      onSignOut: _signOut,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  void _setThemeMode(ThemeMode mode) {
    setState(() => _selectedThemeMode = mode);
    widget.onThemeModeChanged?.call(mode);
  }
}

class _SettingsHero extends StatelessWidget {
  const _SettingsHero({required this.displayName, required this.email});

  final String displayName;
  final String email;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final name = displayName.trim().isEmpty ? 'FocusLane' : displayName.trim();

    return FocusCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ajustes',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Administra tu cuenta, el aspecto de la app y las preferencias que afectan a toda la navegación.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          );
          final badges = Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FocusBadge(label: name, color: scheme.primary),
              if (email.isNotEmpty)
                FocusBadge(label: email, color: scheme.secondary),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [copy, const SizedBox(height: 16), badges],
            );
          }

          return Row(
            children: [
              Expanded(child: copy),
              const SizedBox(width: 20),
              badges,
            ],
          );
        },
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.displayName,
    required this.photoUrl,
    required this.nameController,
    required this.bioController,
    required this.saving,
    required this.onPickPhoto,
    required this.onSave,
  });

  final String displayName;
  final String photoUrl;
  final TextEditingController nameController;
  final TextEditingController bioController;
  final bool saving;
  final VoidCallback onPickPhoto;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final scheme = Theme.of(context).colorScheme;
    final name =
        displayName.isEmpty ? (user?.email ?? 'Sin nombre') : displayName;

    return FocusCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FocusSectionHeader(
            title: 'Perfil y cuenta',
            subtitle: 'Datos visibles de tu usuario en FocusLane.',
            icon: Icons.account_circle_outlined,
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: scheme.primaryContainer,
                foregroundColor: scheme.onPrimaryContainer,
                backgroundImage:
                    photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                child:
                    photoUrl.isEmpty
                        ? Text(
                          _initialFrom(name),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        )
                        : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user?.email ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    FocusSecondaryButton(
                      label: 'Cambiar foto',
                      icon: Icons.photo_camera_outlined,
                      onPressed: onPickPhoto,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Nombre de usuario',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: bioController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Biografía',
              alignLabelWithHint: true,
              prefixIcon: Icon(Icons.notes_outlined),
            ),
          ),
          const SizedBox(height: 14),
          FocusPrimaryButton(
            label: 'Guardar perfil',
            icon: Icons.save_outlined,
            isLoading: saving,
            fullWidth: true,
            onPressed: saving ? null : onSave,
          ),
        ],
      ),
    );
  }
}

class _AppearanceCard extends StatelessWidget {
  const _AppearanceCard({
    required this.selectedThemeMode,
    required this.onChanged,
  });

  final ThemeMode selectedThemeMode;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return FocusCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FocusSectionHeader(
            title: 'Apariencia',
            subtitle: 'Elige cómo se muestra FocusLane en este dispositivo.',
            icon: Icons.palette_outlined,
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 420;
              final button = SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.light,
                    label: Text('Claro'),
                    icon: Icon(Icons.light_mode_outlined),
                  ),
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.dark,
                    label: Text('Oscuro'),
                    icon: Icon(Icons.dark_mode_outlined),
                  ),
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.system,
                    label: Text('Sistema'),
                    icon: Icon(Icons.settings_suggest_outlined),
                  ),
                ],
                selected: {selectedThemeMode},
                onSelectionChanged: (selection) => onChanged(selection.first),
              );

              if (compact) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: button,
                );
              }
              return button;
            },
          ),
        ],
      ),
    );
  }
}

class _ModulesCard extends StatelessWidget {
  const _ModulesCard({required this.visibility, required this.onChanged});

  final ModuleVisibilityService visibility;
  final void Function(String route, bool enabled) onChanged;

  @override
  Widget build(BuildContext context) {
    return FocusCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FocusSectionHeader(
            title: 'Módulos activos',
            subtitle:
                'Controla qué módulos aparecen en la navegación principal.',
            icon: Icons.dashboard_customize_outlined,
            trailing: TextButton(
              onPressed:
                  () => Navigator.of(context).pushNamed(AppRoutes.modules),
              child: const Text('Ver detalle'),
            ),
          ),
          const SizedBox(height: 16),
          ValueListenableBuilder<Set<String>>(
            valueListenable: visibility.hiddenRoutes,
            builder: (context, hiddenRoutes, _) {
              return Column(
                children: [
                  for (
                    var i = 0;
                    i < ModuleVisibilityService.modules.length;
                    i++
                  ) ...[
                    _ModuleSwitchTile(
                      definition: ModuleVisibilityService.modules[i],
                      enabled:
                          !hiddenRoutes.contains(
                            ModuleVisibilityService.modules[i].route,
                          ),
                      onChanged:
                          (enabled) => onChanged(
                            ModuleVisibilityService.modules[i].route,
                            enabled,
                          ),
                    ),
                    if (i != ModuleVisibilityService.modules.length - 1)
                      Divider(
                        height: 1,
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ModuleSwitchTile extends StatelessWidget {
  const _ModuleSwitchTile({
    required this.definition,
    required this.enabled,
    required this.onChanged,
  });

  final ModuleVisibilityDefinition definition;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tone = enabled ? scheme.primary : scheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: enabled ? 0.14 : 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: tone.withValues(alpha: 0.2)),
            ),
            child: Icon(definition.icon, color: tone, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _moduleTitle(definition),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  enabled
                      ? 'Visible en la navegación'
                      : 'Oculto en la navegación',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: enabled ? scheme.primary : scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(value: enabled, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _NotificationAccessCard extends StatelessWidget {
  const _NotificationAccessCard({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return FocusCard(
      onTap: onOpen,
      child: Row(
        children: [
          Expanded(
            child: FocusSectionHeader(
              title: 'Notificaciones',
              subtitle: 'Gestiona permisos, pruebas y recordatorios globales.',
              icon: Icons.notifications_active_outlined,
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityCard extends StatelessWidget {
  const _SecurityCard({
    required this.passwordController,
    required this.passwordConfirmController,
    required this.changingPassword,
    required this.onChangePassword,
  });

  final TextEditingController passwordController;
  final TextEditingController passwordConfirmController;
  final bool changingPassword;
  final VoidCallback onChangePassword;

  @override
  Widget build(BuildContext context) {
    return FocusCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FocusSectionHeader(
            title: 'Seguridad',
            subtitle: 'Actualiza tu contraseña cuando lo necesites.',
            icon: Icons.lock_outline_rounded,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Nueva contraseña',
              prefixIcon: Icon(Icons.password_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: passwordConfirmController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Confirmar contraseña',
              prefixIcon: Icon(Icons.password_rounded),
            ),
          ),
          const SizedBox(height: 14),
          FocusSecondaryButton(
            label: 'Actualizar contraseña',
            icon: Icons.verified_user_outlined,
            fullWidth: true,
            onPressed: changingPassword ? null : onChangePassword,
          ),
          if (changingPassword) ...[
            const SizedBox(height: 10),
            const LinearProgressIndicator(),
          ],
        ],
      ),
    );
  }
}

class _SignOutCard extends StatelessWidget {
  const _SignOutCard({required this.signingOut, required this.onSignOut});

  final bool signingOut;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FocusCard(
      elevated: false,
      backgroundColor: scheme.errorContainer.withValues(alpha: 0.16),
      borderSide: BorderSide(color: scheme.error.withValues(alpha: 0.28)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FocusSectionHeader(
            title: 'Cerrar sesión',
            subtitle: 'Sal de tu cuenta en este dispositivo.',
            icon: Icons.logout_rounded,
            trailing:
                signingOut
                    ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.error,
                      ),
                    )
                    : null,
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: signingOut ? null : onSignOut,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Cerrar sesión'),
              style: OutlinedButton.styleFrom(
                foregroundColor: scheme.error,
                side: BorderSide(color: scheme.error.withValues(alpha: 0.45)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _initialFrom(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return 'F';
  return trimmed.substring(0, 1).toUpperCase();
}

String _moduleTitle(ModuleVisibilityDefinition definition) {
  switch (definition.route) {
    case AppRoutes.studyDashboard:
      return 'Estudio';
    case AppRoutes.foodDashboard:
      return 'Alimentación';
    case AppRoutes.gymDashboard:
      return 'Gimnasio';
    case AppRoutes.habitsDashboard:
      return 'Hábitos';
    default:
      return definition.title;
  }
}
