// lib/screens/meditation/timer/timer_session_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../services/meditation_firestore_service.dart';
import '../models/meditation_models.dart';

class TimerSessionScreen extends StatefulWidget {
  const TimerSessionScreen({super.key});
  static const route = '/meditation/timer';

  @override
  State<TimerSessionScreen> createState() => _TimerSessionScreenState();
}

class _TimerSessionScreenState extends State<TimerSessionScreen> {
  int _seconds = 300;
  Timer? _timer;
  bool _running = false;

  final _title = TextEditingController(text: 'Meditación (temporizador)');
  int? _moodBefore;
  int? _moodAfter;

  // ambiente
  final _player = AudioPlayer();
  String _ambience = 'none';
  double _volume = 0.4;

  int get _initial => _presetSeconds ?? 300;
  int? _presetSeconds;

  @override
  void dispose() {
    _timer?.cancel();
    _player.dispose();
    super.dispose();
  }

  void _start() {
    _timer?.cancel();
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds <= 0) {
        t.cancel();
        setState(() => _running = false);
        _saveSession();
      } else {
        setState(() => _seconds--);
      }
    });
  }

  void _stop() {
    _timer?.cancel();
    setState(() => _running = false);
  }

  Future<void> _saveSession() async {
    final duration = (_initial - _seconds).clamp(0, _initial);
    if (duration <= 0) return;
    await MeditationFirestoreService.I.addSession(
      MeditationSession(
        id: '',
        title: _title.text.trim().isEmpty ? 'Meditación' : _title.text.trim(),
        type: SessionType.timer,
        durationSec: duration,
        date: DateTime.now(),
        moodBefore: _moodBefore,
        moodAfter: _moodAfter,
      ),
    );
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sesión guardada')));
      Navigator.pop(context);
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Temporizador')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: ListView(
          children: [
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Título (opcional)'),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children:
                  [3, 5, 10, 15, 20, 30, 45, 60].map((m) {
                    final sec = m * 60;
                    final sel = _presetSeconds == sec;
                    return ChoiceChip(
                      label: Text('${m}m'),
                      selected: sel,
                      onSelected: (_) {
                        setState(() {
                          _presetSeconds = sec;
                          _seconds = sec;
                        });
                      },
                    );
                  }).toList(),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                _format(_seconds),
                style: Theme.of(context).textTheme.displayMedium,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.icon(
                  icon: Icon(_running ? Icons.pause : Icons.play_arrow),
                  label: Text(_running ? 'Pausar' : 'Iniciar'),
                  onPressed: () => _running ? _stop() : _start(),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.stop),
                  label: const Text('Reiniciar'),
                  onPressed: () {
                    _timer?.cancel();
                    setState(() {
                      _running = false;
                      _seconds = _initial;
                    });
                  },
                ),
              ],
            ),
            const Divider(height: 24),
            _moodRow(
              'Antes',
              _moodBefore,
              (v) => setState(() => _moodBefore = v),
            ),
            _moodRow(
              'Después',
              _moodAfter,
              (v) => setState(() => _moodAfter = v),
            ),
            const Divider(height: 24),
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
            const SizedBox(height: 16),
            if (!_running)
              FilledButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Guardar ahora'),
                onPressed: _saveSession,
              ),
          ],
        ),
      ),
    );
  }

  String _format(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  Widget _moodRow(String title, int? value, void Function(int) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(title)),
          Wrap(
            spacing: 8,
            children: List.generate(5, (i) {
              final v = i + 1;
              final sel = v == value;
              return GestureDetector(
                onTap: () => onChanged(v),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor:
                      sel
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                  child: Text(
                    ['😞', '🙁', '😐', '🙂', '😌'][i],
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
