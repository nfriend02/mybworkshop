import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_theme.dart';
import '../../../shared/api/gemini_client.dart';
import '../../../shared/api/nlp_action.dart';
import '../../../shared/utils/byte_label.dart';
import '../../../shared/utils/download_file.dart';
import '../../../shared/utils/pick_files.dart';
import '../../../shared/utils/record_job.dart';
import '../../../shared/widgets/feature_scaffold.dart';
import '../../../shared/widgets/nlp_request_bar.dart';
import '../../../shared/widgets/scroll_paged_list.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/upload_drop_zone.dart';
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
    if (_frames.isNotEmpty) await _build();
  }

  Future<void> _load(List<PickedBytes> files) async {
    setState(() {
      _frames
        ..clear()
        ..addAll(files.map((file) => _Frame(name: file.name, bytes: file.bytes)));
      _gif = null;
      _error = null;
    });
    await _build();
  }

  Future<void> _build() async {
    if (_frames.isEmpty || _busy) return;
    setState(() => _busy = true);
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
      scrollable: _frames.isEmpty,
      child: _frames.isEmpty
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                NlpRequestBar(
                  tool: 'gif-generator',
                  hint: '예: 12FPS로 만들어 줘',
                  ask: askGifGenerator,
                  onAnswer: _onNlp,
                ),
                const SizedBox(height: 12),
                UploadDropZone(
                  title: '사진들을 놓아요',
                  subtitle: '여러 장을 올리면 순서대로 GIF가 됩니다',
                  buttonLabel: '업로드',
                  multiple: true,
                  onPicked: _load,
                  accent: AppTheme.butter,
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                NlpRequestBar(
                  tool: 'gif-generator',
                  hint: '예: 8FPS로 천천히',
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
                  onChangeEnd: (_) => _build(),
                ),
                Expanded(
                  child: ScrollPagedList<_Frame>(
                    items: _frames,
                    itemBuilder: (context, frame, index) => SectionCard(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.memory(frame.bytes, width: 64, height: 64, fit: BoxFit.cover),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(frame.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 6),
                                LinearProgressIndicator(value: frame.progress == 0 ? null : frame.progress),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: '이 프레임 저장',
                            onPressed: () => downloadFile(context, bytes: frame.bytes, filename: frame.name, mimeType: 'image/png'),
                            icon: const Icon(Icons.download_rounded),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_error != null) Text(_error!, style: GoogleFonts.notoSansKr(color: AppTheme.coral, fontWeight: FontWeight.w700)),
                if (_gif != null)
                  SectionCard(
                    color: AppTheme.butter,
                    child: Row(
                      children: [
                        Image.memory(_gif!, height: 72, fit: BoxFit.contain),
                        const SizedBox(width: 12),
                        Expanded(child: Text('완성 GIF · ${byteLabel(_gif!.length)}', style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w800))),
                        FilledButton.icon(
                          onPressed: () => downloadFile(context, bytes: _gif!, filename: 'workshop.gif', mimeType: 'image/gif'),
                          icon: const Icon(Icons.download_rounded),
                          label: const Text('다운로드'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
