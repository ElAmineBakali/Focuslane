// lib/screens/meditation/breathing/breathing_coach_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:vibration/vibration.dart';

import '../services/meditation_firestore_service.dart';
import '../models/meditation_models.dart';

class BreathingCoachScreen extends StatefulWidget {
  const BreathingCoachScreen({super.key});
  static const route = '/meditation/breath';

  @override
  State<BreathingCoachScreen> createState() => _BreathingCoachScreenState();
}

class _BreathingCoachScreenState extends State<BreathingCoachScreen> {
  // --- Preset & Dropdown (seguro)
  BreathPreset? _selected;
  String? _selectedId;
  final BreathPreset _fallback = BreathPreset(
    id: '_local_fallback',
    name: 'Box 4-4-4-4',
    inhale: 4,
    hold: 4,
    exhale: 4,
    hold2: 4,
    cycles: 6,
    vibration: true,
    visualStyle: 'circle',
  );

  // --- Ciclos / fase
  int _cycle = 1;
  String _phase = 'Inhala';
  int _phaseLeft = 0;
  Timer? _timer;

  // --- Animación simple (controlada por estilos)
  double _scale = 0.9;

  // --- Ambiente
  final _player = AudioPlayer();
  String _ambience = 'none';
  double _volume = 0.4;

  @override
  void initState() {
    super.initState();
    _selected = _fallback;
    _phaseLeft = _selected!.inhale;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _setAmbience(String key) async {
    _ambience = key;
    await _player.stop();
    if (key == 'none') return;
    final asset = switch (key) {
      'rain' => 'assets/audio/ambience/rain.mp3',
      'forest' => 'assets/audio/ambience/forest.mp3',
      'fire' => 'assets/audio/ambience/fireplace.mp3',
      'river' => 'assets/audio/ambience/river.mp3',
      _ => '',
    };
    if (asset.isEmpty) return;
    await _player.setAsset(asset);
    _player.setLoopMode(LoopMode.one);
    _player.setVolume(_volume);
    _player.play();
    if (mounted) setState(() {});
  }

  void _start() {
    _timer?.cancel();
    final p = _selected ?? _fallback;
    setState(() {
      _cycle = 1;
      _phase = 'Inhala';
      _phaseLeft = p.inhale;
      _scale = 1.15;
    });
    _haptic();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_phaseLeft <= 0) {
        _nextPhase();
      } else {
        setState(() => _phaseLeft--);
      }
    });
  }

  void _stop() {
    _timer?.cancel();
    setState(() => _scale = 0.9);
  }

  Future<void> _haptic() async {
    final p = _selected ?? _fallback;
    if (!p.vibration) return;
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(duration: 35);
    }
  }

  void _nextPhase() {
    final p = _selected ?? _fallback;
    setState(() {
      if (_phase == 'Inhala') {
        if (p.hold > 0) {
          _phase = 'Mantén';
          _phaseLeft = p.hold;
        } else {
          _phase = 'Exhala';
          _phaseLeft = p.exhale;
        }
        _scale = 1.15;
      } else if (_phase == 'Mantén') {
        _phase = 'Exhala';
        _phaseLeft = p.exhale;
        _scale = 0.75;
      } else if (_phase == 'Exhala') {
        if (p.hold2 > 0) {
          _phase = 'Mantén';
          _phaseLeft = p.hold2;
          _scale = 0.75;
        } else {
          _advanceCycleOrFinish();
          return;
        }
      } else {
        _advanceCycleOrFinish();
        return;
      }
    });
    _haptic();
  }

  void _advanceCycleOrFinish() {
    final p = _selected ?? _fallback;
    if (_cycle >= p.cycles) {
      _timer?.cancel();
      MeditationFirestoreService.I.addSession(
        MeditationSession(
          id: '',
          title: p.name,
          type: SessionType.breath,
          durationSec: (p.inhale + p.hold + p.exhale + p.hold2) * p.cycles,
          date: DateTime.now(),
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sesión de respiración guardada')),
        );
        setState(() => _scale = 0.9);
      }
    } else {
      setState(() {
        _cycle++;
        _phase = 'Inhala';
        _phaseLeft = p.inhale;
        _scale = 1.15;
      });
      _haptic();
    }
  }

  Widget _visual() {
    final style = (_selected ?? _fallback).visualStyle;
    final color = Theme.of(context).colorScheme.primaryContainer;

    if (style == 'dot') {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
        width: 50 * _scale,
        height: 50 * _scale,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
    }
    if (style == 'wave') {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
        width: 240,
        height: 80,
        alignment: Alignment.center,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Align(
                alignment: Alignment((_scale - 1.0), 0),
                child: Container(width: 240, height: 80, color: color),
              ),
            ],
          ),
        ),
      );
    }
    // 'circle'
    return AnimatedContainer(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
      width: 220 * _scale,
      height: 220 * _scale,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = _selected ?? _fallback;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Respiración guiada'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Presets de respiración',
            onPressed:
                () => Navigator.pushNamed(context, '/meditation/presets'),
          ),
          IconButton(
            icon: const Icon(Icons.library_music),
            tooltip: 'Biblioteca guiada',
            onPressed: () => Navigator.pushNamed(context, '/meditation/guided'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: ListView(
          children: [
            // ---------- PRESET (Dropdown seguro con id String)
            StreamBuilder<List<BreathPreset>>(
              stream: MeditationFirestoreService.I.watchPresets(),
              builder: (context, s) {
                final presets = (s.data ?? []);
                final byId = <String, BreathPreset>{
                  for (final pr in presets) pr.id: pr,
                };
                final items =
                    byId.values
                        .map(
                          (pr) => DropdownMenuItem<String>(
                            value: pr.id,
                            child: Text(pr.name),
                          ),
                        )
                        .toList();

                final hasSelected =
                    _selectedId != null &&
                    items.any((it) => it.value == _selectedId);

                return DropdownButtonFormField<String>(
                  initialValue: hasSelected ? _selectedId : null,
                  items: items,
                  onChanged: (id) {
                    final next = (id != null) ? byId[id] : null;
                    setState(() {
                      _selectedId = id;
                      _selected = next ?? _fallback;
                      _phase = 'Inhala';
                      _phaseLeft = (_selected ?? _fallback).inhale;
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Preset'),
                  hint: Text(p.name),
                );
              },
            ),
            const SizedBox(height: 12),

            // ---------- VISUAL limpio, sin solapar textos
            Center(child: _visual()),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _pill('Fase', _phase),
                _pill('Queda', '${_phaseLeft}s'),
                _pill('Ciclo', '$_cycle/${p.cycles}'),
              ],
            ),

            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Iniciar'),
                  onPressed: _start,
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.stop),
                  label: const Text('Parar'),
                  onPressed: _stop,
                ),
              ],
            ),

            const Divider(height: 28),

            // ---------- Ambiente
            Text(
              'Ambiente (opcional)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Ninguno'),
                  selected: _ambience == 'none',
                  onSelected: (_) => _setAmbience('none'),
                ),
                ChoiceChip(
                  label: const Text('Lluvia'),
                  selected: _ambience == 'rain',
                  onSelected: (_) => _setAmbience('rain'),
                ),
                ChoiceChip(
                  label: const Text('Bosque'),
                  selected: _ambience == 'forest',
                  onSelected: (_) => _setAmbience('forest'),
                ),
                ChoiceChip(
                  label: const Text('Chimenea'),
                  selected: _ambience == 'fire',
                  onSelected: (_) => _setAmbience('fire'),
                ),
                ChoiceChip(
                  label: const Text('Río'),
                  selected: _ambience == 'river',
                  onSelected: (_) => _setAmbience('river'),
                ),
              ],
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.volume_up),
              title: Slider(
                value: _volume,
                onChanged: (v) {
                  setState(() => _volume = v);
                  _player.setVolume(_volume);
                },
                min: 0,
                max: 1,
              ),
              trailing: Text('${(_volume * 100).round()}%'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String a, String b) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Row(
        children: [
          Text('$a: '),
          Text(b, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
