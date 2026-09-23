import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_theme.dart';
import '../../../shared/api/gemini_client.dart';
import '../../../shared/api/nlp_action.dart';
import '../../../shared/utils/byte_label.dart';
import '../../../shared/utils/pick_files.dart';
import '../../../shared/utils/download_file.dart';
import '../../../shared/utils/record_job.dart';
import '../../../shared/widgets/feature_scaffold.dart';
import '../../../shared/widgets/nlp_request_bar.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/upload_drop_zone.dart';
import '../domain/gemini_bridge.dart';
import '../domain/gif_clip.dart';

enum GifTool { resize, crop, downsizing, convert, rotate, optimize, reverse, speed, cut }

class _Export {
  const _Export({
    required this.title,
    required this.filename,
    required this.mime,
    required this.bytes,
  });

  final String title;
  final String filename;
  final String mime;
  final Uint8List bytes;
}

class GifEditorView extends StatefulWidget {
  const GifEditorView({super.key});

  @override
  State<GifEditorView> createState() => _GifEditorViewState();
}

class _GifEditorViewState extends State<GifEditorView> {
  Uint8List? _originalBytes;
  GifClip? _clip;
  GifTool _tool = GifTool.resize;
  _Export? _export;
  var _busy = false;
  var _lock = true;
  double _width = 240;
  double _height = 180;
  double _inset = 0.12;
  double _scale = 0.5;
  double _speed = 1;
  int _rotate = 90;
  RangeValues _cut = const RangeValues(0, 1);
  String? _error;

  Future<void> _load(List<PickedBytes> files) async {
    final file = files.first;
    try {
      final clip = GifClip.decode(file.bytes, file.name);
      setState(() {
        _originalBytes = file.bytes;
        _clip = clip;
        _width = clip.width.toDouble();
        _height = clip.height.toDouble();
        _cut = RangeValues(0, (clip.frameCount - 1).toDouble());
        _export = null;
        _error = null;
      });
      if (!mounted) return;
      await recordJob(context, tool: 'gif-editor', title: 'GIF 업로드', detail: file.name);
    } catch (error) {
      setState(() => _error = '$error');
    }
  }

  Future<void> _onNlp(GeminiAnswer answer) async {
    final clip = _clip;
    final action = NlpAction.tryParse(answer.text);
    if (clip == null || action == null || action.tool.isEmpty) return;
    final tool = GifTool.values.where((item) => item.name == action.tool).firstOrNull;
    if (tool == null) return;
    setState(() => _tool = tool);
    if (action.width != null) _width = action.width!.toDouble();
    if (action.height != null) _height = action.height!.toDouble();
    if (action.delayMs != null && clip.delayMs > 0) {
      _speed = (clip.delayMs / action.delayMs!).clamp(0.25, 4);
    }
    await _go();
  }

  Future<void> _go() async {
    final clip = _clip;
    if (clip == null || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final export = _build(clip);
      if (!mounted) return;
      setState(() => _export = export);
      await recordJob(
        context,
        tool: 'gif-editor',
        title: export.title,
        detail: export.filename,
        extra: {'status': 'done'},
      );
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  _Export _build(GifClip clip) {
    final stem = fileStem(clip.name);
    switch (_tool) {
      case GifTool.resize:
        final edited = clip.resized(_width.round(), _height.round());
        return _Export(
          title: 'Resized GIF',
          filename: '${stem}_resized.gif',
          mime: 'image/gif',
          bytes: edited.encode(),
        );
      case GifTool.crop:
        final edited = clip.cropped(_inset);
        return _Export(
          title: 'Cropped GIF',
          filename: '${stem}_crop.gif',
          mime: 'image/gif',
          bytes: edited.encode(),
        );
      case GifTool.downsizing:
        final edited = clip.scaled(_scale);
        return _Export(
          title: 'Downsized GIF',
          filename: '${stem}_small.gif',
          mime: 'image/gif',
          bytes: edited.encode(),
        );
      case GifTool.convert:
        return _Export(
          title: 'Converted image',
          filename: '${stem}_converted.png',
          mime: 'image/png',
          bytes: clip.toPng(),
        );
      case GifTool.rotate:
        final edited = clip.rotated(_rotate);
        return _Export(
          title: 'Rotated GIF',
          filename: '${stem}_rotated.gif',
          mime: 'image/gif',
          bytes: edited.encode(),
        );
      case GifTool.optimize:
        return _Export(
          title: 'Optimized GIF',
          filename: '${stem}_opt.gif',
          mime: 'image/gif',
          bytes: clip.optimized().encode(),
        );
      case GifTool.reverse:
        return _Export(
          title: 'Reversed GIF',
          filename: '${stem}_reverse.gif',
          mime: 'image/gif',
          bytes: clip.reversed().encode(),
        );
      case GifTool.speed:
        final delay = (clip.delayMs / _speed).round();
        return _Export(
          title: 'Speed GIF',
          filename: '${stem}_speed.gif',
          mime: 'image/gif',
          bytes: clip.withDelay(delay).encode(),
        );
      case GifTool.cut:
        final edited = clip.cut(_cut.start.round(), _cut.end.round());
        return _Export(
          title: 'Cut GIF',
          filename: '${stem}_cut.gif',
          mime: 'image/gif',
          bytes: edited.encode(),
        );
    }
  }

  void _resetResize() {
    final clip = _clip;
    if (clip == null) return;
    setState(() {
      _width = clip.width.toDouble();
      _height = clip.height.toDouble();
    });
  }

  void _setWidth(double value) {
    final clip = _clip;
    setState(() {
      _width = value;
      if (_lock && clip != null && clip.width > 0) {
        _height = value * clip.height / clip.width;
      }
    });
  }

  void _setHeight(double value) {
    final clip = _clip;
    setState(() {
      _height = value;
      if (_lock && clip != null && clip.height > 0) {
        _width = value * clip.width / clip.height;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final clip = _clip;
    return FeatureScaffold(
      title: 'GIF 편집',
      subtitle: '원본을 올리고 오른쪽 도구에서 하나만 골라요',
      emoji: '🎬',
      accent: const Color(0xFFFFC2D4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NlpRequestBar(
            tool: 'gif-editor',
            hint: '예: 가로 240으로 줄이고 빠르게 재생해 줘',
            ask: askGifEditor,
            onAnswer: _onNlp,
          ),
          const SizedBox(height: 16),
          if (clip == null || _originalBytes == null)
            UploadDropZone(
              title: 'GIF를 여기에 놓아요',
              subtitle: '드래그하거나 버튼으로 고를 수 있어요',
              buttonLabel: 'Select File',
              onPicked: _load,
              accent: const Color(0xFFFFC2D4),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final sideBySide = constraints.maxWidth >= 700;
                final original = _originalCard(clip);
                final tools = _toolsCard(clip);
                if (!sideBySide) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [original, const SizedBox(height: 12), tools],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: original),
                    const SizedBox(width: 12),
                    Expanded(child: tools),
                  ],
                );
              },
            ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: GoogleFonts.notoSansKr(color: AppTheme.coral, fontWeight: FontWeight.w700)),
          ],
          if (_export != null) ...[
            const SizedBox(height: 12),
            _resultCard(_export!),
          ],
        ],
      ),
    );
  }

  Widget _originalCard(GifClip clip) {
    return SectionCard(
      color: const Color(0xFFFFF7FB),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Original GIF', style: GoogleFonts.fredoka(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.memory(_originalBytes!, height: 180, fit: BoxFit.contain),
          ),
          const SizedBox(height: 8),
          Text(clip.name, style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w800)),
          Text(
            '${clip.width}×${clip.height} · ${clip.frameCount}프레임 · ${clip.delayMs}ms · ${byteLabel(_originalBytes!.length)}',
            style: GoogleFonts.notoSansKr(color: AppTheme.muted, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _toolsCard(GifClip clip) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Editor Tools', style: GoogleFonts.fredoka(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tool in GifTool.values)
                ChoiceChip(
                  label: Text(tool.name[0].toUpperCase() + tool.name.substring(1)),
                  selected: _tool == tool,
                  onSelected: (_) => setState(() => _tool = tool),
                ),
            ],
          ),
          const SizedBox(height: 14),
          _panel(clip),
        ],
      ),
    );
  }

  Widget _panel(GifClip clip) {
    return switch (_tool) {
      GifTool.resize => _resizePanel(clip),
      GifTool.crop => _sliderPanel('가장자리를 얼마나 잘라낼까요', _inset, 0, 0.4, (value) => setState(() => _inset = value)),
      GifTool.downsizing => _sliderPanel('줄일 비율', _scale, 0.2, 1, (value) => setState(() => _scale = value)),
      GifTool.convert => _actionRow('첫 프레임을 PNG로 저장해요'),
      GifTool.rotate => _sliderPanel('회전 각도', _rotate.toDouble(), 0, 270, (value) => setState(() => _rotate = value.round()), divisions: 3),
      GifTool.optimize => _actionRow('색 수와 크기를 줄여요'),
      GifTool.reverse => _actionRow('프레임 순서를 뒤집어요'),
      GifTool.speed => _sliderPanel('재생 배속', _speed, 0.25, 4, (value) => setState(() => _speed = value)),
      GifTool.cut => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('남길 프레임 ${ _cut.start.round()}–${_cut.end.round()}', style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w700)),
          RangeSlider(
            values: _cut,
            min: 0,
            max: (clip.frameCount - 1).toDouble(),
            divisions: clip.frameCount > 1 ? clip.frameCount - 1 : null,
            onChanged: (value) => setState(() => _cut = value),
          ),
          _goButton(),
        ],
      ),
    };
  }

  Widget _resizePanel(GifClip clip) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('X ${_width.round()}', style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w800)),
            const Spacer(),
            IconButton(
              tooltip: _lock ? '비율 잠금' : '비율 풀기',
              onPressed: () => setState(() => _lock = !_lock),
              icon: Icon(_lock ? Icons.lock_rounded : Icons.lock_open_rounded, color: AppTheme.coral),
            ),
            Text('Y ${_height.round()}', style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w800)),
          ],
        ),
        Slider(value: _width.clamp(8, 2048), min: 8, max: 2048, onChanged: _setWidth),
        Slider(value: _height.clamp(8, 2048), min: 8, max: 2048, onChanged: _setHeight),
        Row(
          children: [
            OutlinedButton(onPressed: _resetResize, child: const Text('Back')),
            const SizedBox(width: 8),
            FilledButton(onPressed: _busy ? null : _go, child: Text(_busy ? '...' : 'Go')),
          ],
        ),
      ],
    );
  }

  Widget _sliderPanel(String label, double value, double min, double max, ValueChanged<double> onChanged, {int? divisions}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('$label ${value.toStringAsFixed(value >= 10 ? 0 : 2)}', style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w700)),
        Slider(value: value.clamp(min, max), min: min, max: max, divisions: divisions, onChanged: onChanged),
        _goButton(),
      ],
    );
  }

  Widget _actionRow(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        _goButton(),
      ],
    );
  }

  Widget _goButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: FilledButton(onPressed: _busy ? null : _go, child: Text(_busy ? '만드는 중' : 'Go')),
    );
  }

  Widget _resultCard(_Export export) {
    return SectionCard(
      color: AppTheme.mint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(export.title, style: GoogleFonts.fredoka(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Image.memory(export.bytes, height: 160, fit: BoxFit.contain),
          const SizedBox(height: 8),
          Text('${export.filename} · ${byteLabel(export.bytes.length)}', style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () => downloadFile(context, bytes: export.bytes, filename: export.filename, mimeType: export.mime),
            icon: const Icon(Icons.download_rounded),
            label: const Text('다운로드'),
          ),
        ],
      ),
    );
  }
}
