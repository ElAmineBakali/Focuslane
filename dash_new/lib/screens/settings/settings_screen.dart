import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:mi_dashboard_personal/theme/prefs.dart';
import '../../theme/theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.currentPreset,
    required this.currentMode,
    required this.onChangePreset,
    required this.onChangeMode,
    required this.currentBackground,
    required this.onChangeBackground,
  });

  final ThemePreset currentPreset;
  final ThemeMode currentMode;
  final void Function(ThemePreset) onChangePreset;
  final void Function(ThemeMode) onChangeMode;
  final BackgroundStyle currentBackground;
  final void Function(BackgroundStyle) onChangeBackground;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _signingOut = false;
  DateTime? _lastSync;
  String _displayName = '';
  String _bio = '';
  bool _loadingProfile = true;
  bool _savingProfile = false;
  
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
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
      
      if (doc.exists) {
        final data = doc.data() ?? {};
        setState(() {
          _displayName = data['displayName'] as String? ?? '';
          _bio = data['bio'] as String? ?? '';
          _nameController.text = _displayName;
          _bioController.text = _bio;
          _loadingProfile = false;
        });
      } else {
        setState(() => _loadingProfile = false);
      }
    } catch (_) {
      setState(() => _loadingProfile = false);
    }
  }
  
  Future<void> _saveUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    setState(() => _savingProfile = true);
    
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('profile')
          .doc('info')
          .set({
        'displayName': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      setState(() {
        _displayName = _nameController.text.trim();
        _bio = _bioController.text.trim();
        _savingProfile = false;
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado')),
      );
    } catch (e) {
      setState(() => _savingProfile = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
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
    final scheme = Theme.of(context).colorScheme;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _sectionTitle(context, 'Cuenta'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _loadingProfile
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: scheme.primaryContainer,
                            child: Icon(
                              Icons.person,
                              color: scheme.primary,
                            ),
                          ),
                          title: Text(
                            _displayName.isEmpty
                                ? user?.email ?? '(sin nombre)'
                                : _displayName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(user?.email ?? '(sin email)'),
                        ),
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Información del perfil',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Nombre para mostrar',
                                  hintText: 'Ej: Juan Pérez',
                                  prefixIcon: Icon(Icons.badge_outlined),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _bioController,
                                decoration: const InputDecoration(
                                  labelText: 'Bio / Descripción',
                                  hintText: 'Cuéntanos sobre ti...',
                                  prefixIcon: Icon(Icons.description_outlined),
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 3,
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  icon: _savingProfile
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.save),
                                  label: const Text('Guardar cambios'),
                                  onPressed: _savingProfile ? null : _saveUserProfile,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Datos técnicos',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'UID: ${user?.uid ?? '-'}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontFamily: 'monospace',
                                      color: scheme.onSurfaceVariant,
                                    ),
                              ),
                              if (user?.metadata.creationTime != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Cuenta creada: ${user!.metadata.creationTime!.toLocal().toString().split('.').first}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              icon: _signingOut
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.logout),
                              label: const Text('Cerrar sesión'),
                              onPressed: _signingOut ? null : _signOut,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 16),
          _sectionTitle(context, 'Apariencia'),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Diseño de color',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        AppTheme.presets
                            .map(
                              (p) => ChoiceChip(
                                label: Text(AppTheme.presetLabel(p)),
                                selected: p == widget.currentPreset,
                                onSelected: (_) => widget.onChangePreset(p),
                              ),
                            )
                            .toList(),
                  ),
                  const SizedBox(height: 12),
                  _previewRow(context),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Modo', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('Claro'),
                        icon: Icon(Icons.wb_sunny_outlined),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text('Oscuro'),
                        icon: Icon(Icons.nightlight_round),
                      ),
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text('Sistema'),
                        icon: Icon(Icons.settings_suggest_outlined),
                      ),
                    ],
                    selected: {widget.currentMode},
                    onSelectionChanged: (set) => widget.onChangeMode(set.first),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),
          Text(
            'Consejo: asegúrate de que los botones y textos tengan buen contraste en ambos modos.',
            style: TextStyle(color: scheme.onSurface.withOpacity(0.7)),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String t) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(t, style: Theme.of(context).textTheme.titleLarge),
  );

  Widget _previewRow(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Card(
            color: s.surface,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  FilledButton(onPressed: () {}, child: const Text('Primario')),
                  const SizedBox(height: 8),
                  FilledButton.tonal(
                    onPressed: () {},
                    child: const Text('Tonal'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Chip(label: Text('Chip')),
                      const SizedBox(width: 8),
                      Icon(Icons.favorite, color: s.primary),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Card(
            color: s.surface,
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                children: [
                  ListTile(
                    title: Text('Texto en surface'),
                    subtitle: Text('Comprueba contraste y legibilidad'),
                  ),
                  SizedBox(height: 8),
                  LinearProgressIndicator(value: 0.6),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
