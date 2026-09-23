import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_theme.dart';
import '../../../shared/api/gemini_client.dart';
import '../../../shared/api/nlp_action.dart';
import '../../../shared/utils/byte_label.dart';
import '../../../shared/utils/download_file.dart';
import '../../../shared/utils/image_sniff.dart';
import '../../../shared/utils/pick_files.dart';
import '../../../shared/utils/record_job.dart';
import '../../../shared/widgets/feature_scaffold.dart';
import '../../../shared/widgets/go_button.dart';
import '../../../shared/widgets/nlp_request_bar.dart';
import '../../../shared/widgets/upload_drop_zone.dart';
import '../../../shared/widgets/waiting_job_tile.dart';
import '../../gif_editor/domain/gif_composer.dart';
import '../domain/fps_limit.dart';
import '../domain/gemini_bridge.dart';

class _Frame {
  _Frame({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
  double progress = 0;
}

class GifGeneratorView extends StatefulWidget {
  const GifGeneratorView({super.key});

  @override
  State<GifGeneratorView> createState() => _GifGeneratorViewState();
}

class _GifGeneratorViewState extends State<GifGeneratorView> {
  final List<_Frame> _frames = [];
  double _fps = 12;
  Uint8List? _gif;
  var _busy = false;
  String? _error;

  Future<void> _onNlp(GeminiAnswer answer) async {
    final action = NlpAction.tryParse(answer.text);
    if (action?.fps == null) return;
    setState(() => _fps = clampGifFps(action!.fps!).toDouble());
  }

  Future<void> _load(List<PickedBytes> files) async {
    final frames = <_Frame>[];
    var skippedHeic = false;
    for (final file in files) {
      final kind = imageKindOf(file.bytes, name: file.name, mimeType: file.mimeType);
      if (kind == ImageKind.heic) {
        skippedHeic = true;
        continue;
      }
      if (kind == ImageKind.unknown) continue;
      frames.add(_Frame(name: ensureImageName(file.name, kind), bytes: file.bytes));
    }
    if (frames.isEmpty) {
      setState(() {
        _frames.clear();
        _gif = null;
        _error = skippedHeic ? heicUploadMessage : '이미지를 찾지 못했어요. PNG, JPG, GIF, WEBP를 올려 주세요';
      });
      return;
    }
    setState(() {
      _frames
        ..clear()
        ..addAll(frames);
      _gif = null;
      _error = skippedHeic ? heicUploadMessage : null;
    });
  }

  Future<void> _build() async {
    if (_frames.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _gif = null;
      for (final frame in _frames) {
        frame.progress = 0;
      }
    });
    try {
      for (final frame in _frames) {
        frame.progress = 0.4;
        if (mounted) setState(() {});
        await Future<void>.delayed(Duration.zero);
        frame.progress = 1;
      }
      final fps = clampGifFps(_fps.round());
      final bytes = await composeGif([for (final frame in _frames) frame.bytes], delayMsForFps(fps));
      if (!mounted) return;
      setState(() => _gif = bytes);
      await recordJob(
        context,
        tool: 'gif-generator',
        title: '$fps FPS GIF',
        detail: '${_frames.length}장',
        extra: {'status': 'done'},
      );
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fps = clampGifFps(_fps.round());
    return FeatureScaffold(
      title: 'GIF 생성',
      subtitle: '사진을 이어 붙이고, 속도는 29FPS를 넘지 않아요',
      emoji: '✨',
      accent: AppTheme.butter,
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              children: [
                NlpRequestBar(
                  tool: 'gif-generator',
                  hint: '예: 12FPS로 만들어 줘',
                  ask: askGifGenerator,
                  onAnswer: _onNlp,
                ),
                const SizedBox(height: 8),
                Text('FPS $fps / 29', style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w800)),
                Slider(
                  value: fps.toDouble(),
                  min: 1,
                  max: 29,
                  divisions: 28,
                  label: '$fps',
                  onChanged: _busy ? null : (value) => setState(() => _fps = value),
                ),
                UploadDropZone(
                  title: '사진들을 놓아요',
                  subtitle: '올린 뒤 GO를 누르면 GIF가 됩니다',
                  buttonLabel: '업로드',
                  multiple: true,
                  onPicked: _load,
                  accent: AppTheme.butter,
                  sideAction: GoButton(
                    busy: _busy,
                    onPressed: _frames.isEmpty ? null : _build,
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: GoogleFonts.notoSansKr(color: AppTheme.coral, fontWeight: FontWeight.w700)),
                ],
                if (_gif == null && _frames.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  for (final frame in _frames) ...[
                    WaitingJobTile(
                      name: frame.name,
                      preview: frame.bytes,
                      progress: _busy && frame.progress == 0 ? null : frame.progress,
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ],
            ),
          ),
          if (_gif != null) ...[
            const SizedBox(height: 8),
            WaitingJobTile(
              name: '완성 GIF · ${byteLabel(_gif!.length)}',
              preview: _gif,
              progress: 1,
              trailing: IconButton(
                tooltip: '다운로드',
                onPressed: () => downloadFile(context, bytes: _gif!, filename: 'workshop.gif', mimeType: 'image/gif'),
                icon: const Icon(Icons.download_rounded),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
