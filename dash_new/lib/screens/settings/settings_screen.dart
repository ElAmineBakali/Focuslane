import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(user?.email ?? '(sin email)'),
                    subtitle: Text('UID: ${user?.uid ?? '-'}'),
                    trailing:
                        _lastSync == null
                            ? const SizedBox.shrink()
                            : Text(
                              'Última sync\n${_lastSync!.toLocal().toString().split(".").first}',
                              textAlign: TextAlign.right,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon:
                              _signingOut
                                  ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Icon(Icons.logout),
                          label: const Text(
                            'Cerrar sesión / Cambiar de cuenta',
                          ),
                          onPressed: _signingOut ? null : _signOut,
                        ),
                      ),
                    ],
                  ),
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
