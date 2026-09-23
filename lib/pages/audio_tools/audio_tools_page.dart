import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../features/audio_tools/domain/wav_tone.dart';
import '../../shared/utils/play_bytes.dart';
import '../../shared/utils/record_job.dart';
import '../../shared/utils/save_bytes.dart';
import '../../shared/widgets/feature_scaffold.dart';

class AudioToolsPage extends StatefulWidget {
  const AudioToolsPage({super.key});

  @override
  State<AudioToolsPage> createState() => _AudioToolsPageState();
}

class _AudioToolsPageState extends State<AudioToolsPage> {
  double _frequency = 440;
  double _seconds = 0.6;
  final _taps = <DateTime>[];
  Timer? _metronome;
  bool _playing = false;

  @override
  void dispose() {
    _metronome?.cancel();
    super.dispose();
  }

  Uint8List _tone({double? hz, double? seconds}) {
    return buildSineWav(
      frequencyHz: hz ?? _frequency,
      seconds: seconds ?? _seconds,
      volume: 0.35,
    );
  }

  Future<void> _play() async {
    final wav = _tone();
    playBytes(wav, 'audio/wav');
    if (!kIsWeb && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('재생은 웹에서 지원해요. WAV는 저장할 수 있어요.')),
      );
    }
    await recordJob(
      context,
      tool: 'audio',
      title: '${_frequency.round()}Hz 톤',
      detail: '${_seconds.toStringAsFixed(1)}s',
    );
  }

  void _tap() {
    final now = DateTime.now();
    setState(() {
      _taps.add(now);
      if (_taps.length > 8) _taps.removeAt(0);
    });
  }

  double? get _bpm {
    if (_taps.length < 2) return null;
    var total = 0;
    for (var i = 1; i < _taps.length; i++) {
      total += _taps[i].difference(_taps[i - 1]).inMilliseconds;
    }
    final avg = total / (_taps.length - 1);
    if (avg <= 0) return null;
    return 60000 / avg;
  }

  void _toggleMetronome() {
    final bpm = _bpm;
    if (_playing) {
      _metronome?.cancel();
      setState(() => _playing = false);
      return;
    }
    if (bpm == null) return;
    final interval = Duration(milliseconds: (60000 / bpm).round().clamp(120, 2000));
    _metronome = Timer.periodic(interval, (_) {
      playBytes(_tone(hz: 880, seconds: 0.08), 'audio/wav');
    });
    setState(() => _playing = true);
  }

  @override
  Widget build(BuildContext context) {
    final bpm = _bpm;
    return FeatureScaffold(
      title: '오디오 도구',
      subtitle: '사인파 톤과 탭 템포',
      emoji: '🎵',
      accent: const Color(0xFFFFD3C4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('주파수 ${_frequency.round()} Hz'),
          Slider(
            value: _frequency,
            min: 110,
            max: 880,
            onChanged: (value) => setState(() => _frequency = value),
          ),
          Text('길이 ${_seconds.toStringAsFixed(1)}초'),
          Slider(
            value: _seconds,
            min: 0.2,
            max: 2,
            onChanged: (value) => setState(() => _seconds = value),
          ),
          FilledButton(onPressed: _play, child: const Text('톤 재생')),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => saveBytes(
              bytes: _tone(),
              filename: 'tone.wav',
              mimeType: 'audio/wav',
            ),
            child: const Text('WAV 저장'),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _tap, child: const Text('템포 탭')),
          const SizedBox(height: 8),
          Text(bpm == null ? '두 번 이상 탭해 주세요' : '${bpm.round()} BPM'),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: bpm == null ? null : _toggleMetronome,
            child: Text(_playing ? '메트로놈 정지' : '메트로놈 시작'),
          ),
        ],
      ),
    );
  }
}
