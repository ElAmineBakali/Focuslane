import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('profile')
          .doc('info')
          .get();
      final data = doc.data() ?? const <String, dynamic>{};

      _displayName = ((data['displayName'] as String?) ?? user.displayName ?? '').trim();
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar el perfil: $e')),
      );
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
        await ref.putFile(File(file.path), SettableMetadata(contentType: 'image/jpeg'));
      }

      final url = await ref.getDownloadURL();
      setState(() => _photoUrl = url);
      await _saveProfile();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar la foto: $e')),
      );
    }
  }

  Future<void> _changePassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _changingPassword) return;

    final pass = _passwordController.text;
    final confirm = _passwordConfirmController.text;
    if (pass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La contraseña debe tener al menos 6 caracteres.')),
      );
      return;
    }
    if (pass != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden.')),
      );
      return;
    }

    setState(() => _changingPassword = true);
    try {
      await user.updatePassword(pass);
      _passwordController.clear();
      _passwordConfirmController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contraseña actualizada.')),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final msg = e.code == 'requires-recent-login'
          ? 'Por seguridad, vuelve a iniciar sesión y prueba de nuevo.'
          : (e.message ?? 'No se pudo cambiar la contraseña.');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes de perfil')),
      body: SafeArea(
        child: _loadingProfile
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Apariencia',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 10),
                          SegmentedButton<ThemeMode>(
                            segments: const [
                              ButtonSegment<ThemeMode>(
                                value: ThemeMode.light,
                                label: Text('Light'),
                                icon: Icon(Icons.light_mode_outlined),
                              ),
                              ButtonSegment<ThemeMode>(
                                value: ThemeMode.dark,
                                label: Text('Dark'),
                                icon: Icon(Icons.dark_mode_outlined),
                              ),
                              ButtonSegment<ThemeMode>(
                                value: ThemeMode.system,
                                label: Text('Sistema'),
                                icon: Icon(Icons.settings_suggest_outlined),
                              ),
                            ],
                            selected: {_selectedThemeMode},
                            onSelectionChanged: (selection) {
                              final mode = selection.first;
                              setState(() => _selectedThemeMode = mode);
                              widget.onThemeModeChanged?.call(mode);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.notifications_active_outlined),
                      title: const Text('Notificaciones globales'),
                      subtitle: const Text('Gestiona recordatorios de todos los módulos'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).pushNamed(AppRoutes.notifications),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.dashboard_customize_outlined),
                      title: const Text('Módulos de la app'),
                      subtitle: const Text('Activa o desactiva módulos visibles en la navegación'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).pushNamed('/modules'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 34,
                                backgroundImage: _photoUrl.isNotEmpty ? NetworkImage(_photoUrl) : null,
                                child: _photoUrl.isEmpty ? const Icon(Icons.person, size: 30) : null,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _displayName.isEmpty ? (user?.email ?? 'Sin nombre') : _displayName,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(user?.email ?? '', style: Theme.of(context).textTheme.bodySmall),
                                    const SizedBox(height: 8),
                                    FilledButton.tonalIcon(
                                      onPressed: _pickAndUploadPhoto,
                                      icon: const Icon(Icons.photo_camera_outlined),
                                      label: const Text('Cambiar foto'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Nombre de usuario',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _bioController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Bio',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _savingProfile ? null : _saveProfile,
                              icon: _savingProfile
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.save_outlined),
                              label: const Text('Guardar perfil'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cambio de contraseña',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Nueva contraseña',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _passwordConfirmController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Confirmar contraseña',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.tonal(
                              onPressed: _changingPassword ? null : _changePassword,
                              child: _changingPassword
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('Actualizar contraseña'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _signingOut ? null : _signOut,
                    icon: const Icon(Icons.logout),
                    label: const Text('Cerrar sesión'),
                  ),
                ],
              ),
      ),
    );
  }
}
