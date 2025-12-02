// lib/screens/meditation/guided/guided_player_screen.dart
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../services/meditation_firestore_service.dart';
import '../models/meditation_models.dart';

class GuidedPlayerScreen extends StatefulWidget {
  const GuidedPlayerScreen({super.key});
  static const route = '/meditation/guided/player';

  @override
  State<GuidedPlayerScreen> createState() => _GuidedPlayerScreenState();
}

class _GuidedPlayerScreenState extends State<GuidedPlayerScreen> {
  final _player = AudioPlayer();
  GuidedAudio? _audio;
  bool _completedLogged = false;
  Stream<Duration>? _posStream;
  Stream<PlayerState>? _stateStream;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is GuidedAudio && _audio == null) {
      _audio = arg;
      _load();
    }
  }

  Future<void> _load() async {
    if (_audio == null) return;
    try {
      if (_audio!.url.startsWith('assets/')) {
        await _player.setAsset(_audio!.url);
      } else {
        await _player.setUrl(_audio!.url);
      }
      _posStream = _player.positionStream;
      _stateStream = _player.playerStateStream;
      _player.play();

      _player.processingStateStream.listen((state) async {
        if (state == ProcessingState.completed && !_completedLogged) {
          _completedLogged = true;
          await _logSession();
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Sesión registrada')));
          }
        }
      });
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo cargar el audio: $e')));
    }
  }

  Future<void> _logSession() async {
    if (_audio == null) return;
    await MeditationFirestoreService.I.addSession(
      MeditationSession(
        id: '',
        title: _audio!.title,
        type: SessionType.guided,
        durationSec: _audio!.durationSec,
        date: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  // --- helpers ---
  Duration _clampDuration(Duration v, Duration min, Duration max) {
    if (v < min) return min;
    if (v > max) return max;
    return v;
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (_audio == null) {
      return const Scaffold(body: Center(child: Text('Sin audio')));
    }

    return Scaffold(
      appBar: AppBar(title: Text(_audio!.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.play_circle_fill, size: 72),
            const SizedBox(height: 8),
            Text(
              '${(_audio!.durationSec / 60).round()} min',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),

            // Barra + tiempo
            StreamBuilder<Duration>(
              stream: _posStream,
              builder: (_, s) {
                final pos = s.data ?? Duration.zero;
                final total =
                    _player.duration ?? Duration(seconds: _audio!.durationSec);

                final safePos = _clampDuration(pos, Duration.zero, total);
                final maxMs = total.inMilliseconds.toDouble().clamp(
                  1.0,
                  double.infinity,
                );
                final valMs = safePos.inMilliseconds.toDouble().clamp(
                  0.0,
                  maxMs,
                );

                return Column(
                  children: [
                    Slider(
                      value: valMs,
                      max: maxMs,
                      onChanged:
                          (v) =>
                              _player.seek(Duration(milliseconds: v.toInt())),
                    ),
                    Text('${_fmt(safePos)} / ${_fmt(total)}'),
                  ],
                );
              },
            ),

            const SizedBox(height: 12),

            // Controles
            StreamBuilder<PlayerState>(
              stream: _stateStream,
              builder: (_, s) {
                final playing = s.data?.playing ?? false;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.replay_10),
                      onPressed: () {
                        final total =
                            _player.duration ??
                            Duration(seconds: _audio!.durationSec);
                        final target = _clampDuration(
                          _player.position - const Duration(seconds: 10),
                          Duration.zero,
                          total,
                        );
                        _player.seek(target);
                      },
                    ),
                    IconButton(
                      iconSize: 40,
                      icon: Icon(
                        playing ? Icons.pause_circle : Icons.play_circle,
                      ),
                      onPressed:
                          () => playing ? _player.pause() : _player.play(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.forward_10),
                      onPressed: () {
                        final total =
                            _player.duration ??
                            Duration(seconds: _audio!.durationSec);
                        final target = _clampDuration(
                          _player.position + const Duration(seconds: 10),
                          Duration.zero,
                          total,
                        );
                        _player.seek(target);
                      },
                    ),
                  ],
                );
              },
            ),

            const Spacer(),

            // Registrar manualmente (por si paras antes del final)
            FilledButton.icon(
              icon: const Icon(Icons.check),
              label: const Text('Terminar y registrar'),
              onPressed: () async {
                await _logSession();
                if (mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
