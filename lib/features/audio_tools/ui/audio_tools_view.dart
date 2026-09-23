import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_theme.dart';
import '../../../shared/api/gemini_client.dart';
import '../../../shared/api/nlp_action.dart';
import '../../../shared/utils/byte_label.dart';
import '../../../shared/utils/download_file.dart';
import '../../../shared/utils/pick_files.dart';
import '../../../shared/utils/play_bytes.dart';
import '../../../shared/utils/record_job.dart';
import '../../../shared/widgets/feature_scaffold.dart';
import '../../../shared/widgets/go_button.dart';
import '../../../shared/widgets/nlp_request_bar.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/upload_drop_zone.dart';
import '../../../shared/widgets/waiting_job_tile.dart';
import '../domain/gemini_bridge.dart';
import '../domain/wav_edit.dart';

enum _AudioTool { compress, convert, speed, volume, denoise }

class AudioToolsView extends StatefulWidget {
  const AudioToolsView({super.key});

  @override
  State<AudioToolsView> createState() => _AudioToolsViewState();
}

class _AudioToolsViewState extends State<AudioToolsView> {
  PickedBytes? _file;
  WavPcm? _wav;
  Uint8List? _result;
  String _resultName = 'audio.wav';
  _AudioTool _tool = _AudioTool.compress;
  double _speed = 1;
  double _gain = 1;
  String? _note;

  Future<void> _load(List<PickedBytes> files) async {
    final file = files.first;
    final wav = WavPcm.tryParse(file.bytes);
    setState(() {
      _file = file;
      _wav = wav;
      _result = null;
      _note = wav == null ? 'WAV 파일을 올리면 압축, 변환, 속도, 볼륨, 노이즈 제거가 적용돼요.' : null;
    });
    if (!mounted) return;
    await recordJob(context, tool: 'audio-tools', title: '오디오 업로드', detail: file.name);
  }

  Future<void> _onNlp(GeminiAnswer answer) async {
    final action = NlpAction.tryParse(answer.text);
    if (action == null) return;
    final tool = _AudioTool.values.where((item) => item.name == action.tool).firstOrNull;
    setState(() {
      if (tool != null) _tool = tool;
      if (action.speed != null) _speed = action.speed!.clamp(0.5, 2);
      if (action.gain != null) _gain = action.gain!.clamp(0, 2);
    });
  }

  Future<void> _apply() async {
    final wav = _wav;
    final file = _file;
    if (wav == null || file == null) {
      setState(() => _note = '편집은 WAV에서 동작해요.');
      return;
    }
    final edited = switch (_tool) {
      _AudioTool.compress => wav.compress(),
      _AudioTool.convert => wav.convert(),
      _AudioTool.speed => wav.atSpeed(_speed),
      _AudioTool.volume => wav.atVolume(_gain),
      _AudioTool.denoise => wav.denoise(),
    };
    final bytes = edited.encode();
    final stem = fileStem(file.name);
    setState(() {
      _result = bytes;
      _resultName = '${stem}_${_tool.name}.wav';
      _note = null;
    });
    if (!mounted) return;
    await recordJob(
      context,
      tool: 'audio-tools',
      title: _tool.name,
      detail: _resultName,
      extra: {'status': 'done'},
    );
  }

  @override
  Widget build(BuildContext context) {
    final peaks = _wav?.peaks(64) ?? _bytePeaks(_file?.bytes);
    return FeatureScaffold(
      title: '오디오 툴킷',
      subtitle: '파형을 보면서 압축, 변환, 속도, 볼륨, 노이즈를 다뤄요',
      emoji: '🎵',
      accent: AppTheme.peach,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NlpRequestBar(
            tool: 'audio-tools',
            hint: '예: 볼륨을 절반으로 낮춰 줘',
            ask: askAudioTools,
            onAnswer: _onNlp,
          ),
          const SizedBox(height: 12),
          UploadDropZone(
            title: '오디오를 놓아요',
            subtitle: 'WAV를 올린 뒤 GO를 누르면 적용해요',
            buttonLabel: 'Select File',
            onPicked: _load,
            accent: AppTheme.peach,
            sideAction: GoButton(
              onPressed: _wav == null ? null : _apply,
            ),
          ),
          if (_file != null) ...[
            const SizedBox(height: 12),
            SectionCard(
              color: const Color(0xFFFFF4EE),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(_file!.name, style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  SizedBox(height: 96, child: CustomPaint(painter: _WavePainter(peaks), child: const SizedBox.expand())),
                ],
              ),
            ),
            if (_result == null) ...[
              const SizedBox(height: 12),
              WaitingJobTile(name: _file!.name, progress: 0),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tool in _AudioTool.values)
                  ChoiceChip(
                    label: Text(_label(tool)),
                    selected: _tool == tool,
                    onSelected: (_) => setState(() => _tool = tool),
                  ),
              ],
            ),
            if (_tool == _AudioTool.speed)
              Slider(value: _speed, min: 0.5, max: 2, divisions: 6, label: '${_speed.toStringAsFixed(1)}x', onChanged: (value) => setState(() => _speed = value)),
            if (_tool == _AudioTool.volume)
              Slider(value: _gain, min: 0, max: 2, divisions: 8, label: _gain.toStringAsFixed(1), onChanged: (value) => setState(() => _gain = value)),
            if (_note != null) ...[
              const SizedBox(height: 8),
              Text(_note!, style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w700)),
            ],
            if (_result != null) ...[
              const SizedBox(height: 12),
              WaitingJobTile(
                name: '$_resultName · ${byteLabel(_result!.length)}',
                progress: 1,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(onPressed: () => playBytes(_result!, 'audio/wav'), icon: const Icon(Icons.play_arrow_rounded)),
                    IconButton(
                      tooltip: '다운로드',
                      onPressed: () => downloadFile(context, bytes: _result!, filename: _resultName, mimeType: 'audio/wav'),
                      icon: const Icon(Icons.download_rounded),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _label(_AudioTool tool) {
    return switch (tool) {
      _AudioTool.compress => '압축',
      _AudioTool.convert => '포맷 변환',
      _AudioTool.speed => '속도 조절',
      _AudioTool.volume => '볼륨 조절',
      _AudioTool.denoise => '노이즈 제거',
    };
  }

  List<double> _bytePeaks(Uint8List? bytes) {
    if (bytes == null || bytes.isEmpty) return const [];
    const bars = 64;
    final size = (bytes.length / bars).ceil();
    return [
      for (var i = 0; i < bars; i++)
        () {
          var peak = 0;
          final start = i * size;
          final end = (start + size).clamp(0, bytes.length);
          for (var j = start; j < end; j++) {
            final centered = (bytes[j] - 128).abs();
            if (centered > peak) peak = centered;
          }
          return peak / 128;
        }(),
    ];
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter(this.peaks);

  final List<double> peaks;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFFF8BA7);
    if (peaks.isEmpty) return;
    final gap = size.width / peaks.length;
    for (var i = 0; i < peaks.length; i++) {
      final height = (peaks[i].clamp(0.05, 1)) * size.height;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(i * gap + 1, (size.height - height) / 2, gap - 2, height),
        const Radius.circular(6),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) => oldDelegate.peaks != peaks;
}
