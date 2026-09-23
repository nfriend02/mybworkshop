import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;

import '../../../app/theme/app_theme.dart';
import '../../../shared/api/gemini_client.dart';
import '../../../shared/api/nlp_action.dart';
import '../../../shared/utils/byte_label.dart';
import '../../../shared/utils/download_file.dart';
import '../../../shared/utils/image_sniff.dart';
import '../../../shared/utils/pick_files.dart';
import '../../../shared/utils/record_job.dart';
import '../../../shared/widgets/feature_scaffold.dart';
import '../../../shared/widgets/nlp_request_bar.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/upload_drop_zone.dart';
import '../domain/gemini_bridge.dart';
import '../domain/gif_clip.dart';
import '../domain/gif_video.dart';

enum GifTool { resize, crop, downsizing, convert, rotate, optimize, reverse, speed, cut }

const _toolLabels = {
  GifTool.resize: 'Resize',
  GifTool.crop: 'Crop',
  GifTool.downsizing: 'Downsizing',
  GifTool.convert: 'Format Convert',
  GifTool.rotate: 'Rotate',
  GifTool.optimize: 'Optimize',
  GifTool.reverse: 'Reverse',
  GifTool.speed: 'Speed',
  GifTool.cut: 'Cut',
};

const _toolIcons = {
  GifTool.resize: Icons.photo_size_select_large_rounded,
  GifTool.crop: Icons.crop_rounded,
  GifTool.downsizing: Icons.compress_rounded,
  GifTool.convert: Icons.swap_horiz_rounded,
  GifTool.rotate: Icons.rotate_right_rounded,
  GifTool.optimize: Icons.auto_fix_high_rounded,
  GifTool.reverse: Icons.replay_rounded,
  GifTool.speed: Icons.speed_rounded,
  GifTool.cut: Icons.content_cut_rounded,
};

const _cropRatios = <(String, double)>[
  ('1:1', 1),
  ('4:3', 4 / 3),
  ('3:4', 3 / 4),
  ('16:9', 16 / 9),
  ('9:16', 9 / 16),
];

const _padColors = <(String, int, int, int)>[
  ('흰색', 255, 255, 255),
  ('검정', 24, 24, 28),
  ('분홍', 255, 194, 212),
];

class _Export {
  const _Export({
    required this.title,
    required this.filename,
    required this.mime,
    required this.bytes,
    required this.width,
    required this.height,
    required this.frames,
    required this.delayMs,
    this.still,
  });

  final String title;
  final String filename;
  final String mime;
  final Uint8List bytes;
  final int width;
  final int height;
  final int frames;
  final int delayMs;
  final Uint8List? still;

  String get info {
    final rate = delayMs <= 0 ? 10 : 1000 / delayMs;
    final fps = rate >= 10 ? rate.toStringAsFixed(0) : rate.toStringAsFixed(1);
    return '${byteLabel(bytes.length)} · $width×$height · $fps FPS · $frames프레임';
  }
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
  var _originalOpen = true;
  var _baseWidth = 240;
  var _baseHeight = 180;
  double _width = 240;
  double _height = 180;
  double _cropRatio = 1;
  var _cropCover = false;
  var _padIndex = 0;
  var _shrinkSize = true;
  var _dropFrames = false;
  var _lowerResolution = false;
  var _rotate = 90;
  var _flipH = false;
  var _flipV = false;
  double _speed = 1;
  RangeValues _cut = const RangeValues(0, 1);
  Uint8List? _preview;
  var _progress = 0.0;
  String? _error;

  img.ColorRgb8 get _pad => img.ColorRgb8(_padColors[_padIndex].$2, _padColors[_padIndex].$3, _padColors[_padIndex].$4);

  double _axisMin(int base) => math.max(1, base * 0.05);

  double _axisMax(int base) {
    final min = _axisMin(base);
    final max = math.min(8192, base * 3).toDouble();
    return max <= min ? min + 1 : max;
  }

  Future<void> _load(List<PickedBytes> files) async {
    final file = files.first;
    final kind = imageKindOf(file.bytes, name: file.name, mimeType: file.mimeType);
    if (kind == ImageKind.heic) {
      setState(() => _error = heicUploadMessage);
      return;
    }
    try {
      final clip = GifClip.decode(file.bytes, ensureImageName(file.name, kind));
      setState(() {
        _originalBytes = file.bytes;
        _clip = clip;
        _baseWidth = clip.width;
        _baseHeight = clip.height;
        _width = clip.width.toDouble();
        _height = clip.height.toDouble();
        _cut = RangeValues(0, (clip.frameCount - 1).toDouble());
        _export = null;
        _progress = 0;
        _originalOpen = true;
        _error = null;
        _preview = _makePreview(clip);
      });
      if (!mounted) return;
      await recordJob(context, tool: 'gif-editor', title: 'GIF 업로드', detail: file.name);
    } catch (error) {
      setState(() => _error = '$error');
    }
  }

  void _clearFile() {
    setState(() {
      _clip = null;
      _originalBytes = null;
      _preview = null;
      _export = null;
      _progress = 0;
      _originalOpen = true;
      _error = null;
    });
  }

  Future<void> _onNlp(GeminiAnswer answer) async {
    final clip = _clip;
    final action = NlpAction.tryParse(answer.text);
    if (clip == null || action == null || action.tool.isEmpty) return;
    final tool = GifTool.values.where((item) => item.name == action.tool).firstOrNull;
    if (tool == null) return;
    setState(() {
      _tool = tool;
      if (action.width != null) _width = action.width!.toDouble().clamp(_axisMin(_baseWidth), _axisMax(_baseWidth));
      if (action.height != null) _height = action.height!.toDouble().clamp(_axisMin(_baseHeight), _axisMax(_baseHeight));
      if (action.delayMs != null && clip.delayMs > 0) {
        _speed = (clip.delayMs / action.delayMs!).clamp(0.25, 4).toDouble();
      }
      _preview = _makePreview(clip);
    });
  }

  void _tune(VoidCallback change) {
    final clip = _clip;
    setState(() {
      change();
      if (clip == null) return;
      try {
        _preview = _makePreview(clip);
      } catch (error) {
        _error = '$error';
      }
    });
  }

  Uint8List _makePreview(GifClip clip) {
    final index = switch (_tool) {
      GifTool.reverse => clip.frameCount - 1,
      GifTool.cut => _cut.start.round().clamp(0, clip.frameCount - 1),
      _ => 0,
    };
    return clip.previewPng((frame) => _transformPreview(frame), frameIndex: index);
  }

  img.Image _transformPreview(img.Image frame) {
    switch (_tool) {
      case GifTool.resize:
        final width = _width.round().clamp(1, 8192).toInt();
        final height = _height.round().clamp(1, 8192).toInt();
        final longest = math.max(width, height);
        final scale = longest > 480 ? 480 / longest : 1.0;
        return img.copyResize(
          frame,
          width: (width * scale).round().clamp(1, 480).toInt(),
          height: (height * scale).round().clamp(1, 480).toInt(),
        );
      case GifTool.crop:
        return cropFrame(frame, widthOverHeight: _cropRatio, cover: _cropCover, pad: _pad);
      case GifTool.downsizing:
        var image = frame;
        if (_shrinkSize) {
          image = img.copyResize(
            image,
            width: (image.width * 0.7).round().clamp(1, image.width).toInt(),
            height: (image.height * 0.7).round().clamp(1, image.height).toInt(),
          );
        }
        if (_lowerResolution) {
          final longest = math.max(image.width, image.height);
          if (longest > 480) {
            final scale = 480 / longest;
            image = img.copyResize(
              image,
              width: (image.width * scale).round().clamp(1, 480).toInt(),
              height: (image.height * scale).round().clamp(1, 480).toInt(),
            );
          }
        }
        return image;
      case GifTool.rotate:
        return flipFrame(img.copyRotate(frame, angle: _rotate % 360), horizontal: _flipH, vertical: _flipV);
      case GifTool.convert:
      case GifTool.optimize:
      case GifTool.reverse:
      case GifTool.speed:
      case GifTool.cut:
        return frame;
    }
  }

  Future<void> _go() async {
    final clip = _clip;
    if (clip == null || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _export = null;
      _progress = 0.35;
      _originalOpen = false;
    });
    await Future<void>.delayed(Duration.zero);
    try {
      final export = await _makeExport(clip);
      if (!mounted) return;
      setState(() {
        _export = export;
        _progress = 1;
      });
      await recordJob(
        context,
        tool: 'gif-editor',
        title: export.title,
        detail: export.filename,
        extra: {'status': 'done'},
      );
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = '$error';
          _originalOpen = true;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<_Export> _makeExport(GifClip clip) async {
    final stem = _prefixedName(clip.name);
    switch (_tool) {
      case GifTool.resize:
        final edited = clip.resized(_width.round(), _height.round());
        return _gifExport('Resized GIF', 'Resized_$stem', edited);
      case GifTool.crop:
        final edited = clip.cropAspect(_cropRatio, cover: _cropCover, pad: _pad);
        return _gifExport('Cropped GIF', 'Cropped_$stem', edited);
      case GifTool.downsizing:
        if (!_shrinkSize && !_dropFrames && !_lowerResolution) {
          throw StateError('사이즈 축소, 프레임 삭제, 해상도 낮추기 중 하나를 골라 주세요');
        }
        final edited = clip.downsized(
          shrinkSize: _shrinkSize,
          dropFrames: _dropFrames,
          lowerResolution: _lowerResolution,
        );
        return _gifExport('Downsized GIF', 'Downsized_$stem', edited);
      case GifTool.convert:
        if (clip.frameCount <= 1) {
          final bytes = clip.toJpg();
          return _Export(
            title: 'Converted JPG',
            filename: 'Converted_${_fileStem(clip.name)}.jpg',
            mime: 'image/jpeg',
            bytes: bytes,
            width: clip.width,
            height: clip.height,
            frames: 1,
            delayMs: clip.delayMs,
            still: bytes,
          );
        }
        final video = await encodeGifVideo(clip);
        return _Export(
          title: video.extension == 'mp4' ? 'Converted MP4' : 'Converted WebM',
          filename: 'Converted_${_fileStem(clip.name)}.${video.extension}',
          mime: video.mime,
          bytes: video.bytes,
          width: clip.width,
          height: clip.height,
          frames: clip.frameCount,
          delayMs: clip.delayMs,
          still: _preview,
        );
      case GifTool.rotate:
        final edited = clip.rotated(_rotate).flipped(horizontal: _flipH, vertical: _flipV);
        return _gifExport('Rotated GIF', 'Rotated_$stem', edited);
      case GifTool.optimize:
        return _gifExport('Optimized GIF', 'Optimized_$stem', clip.optimized());
      case GifTool.reverse:
        return _gifExport('Reversed GIF', 'Reversed_$stem', clip.reversed());
      case GifTool.speed:
        final delay = (clip.delayMs / _speed).round();
        return _gifExport('Speed GIF', 'Speed_$stem', clip.withDelay(delay));
      case GifTool.cut:
        return _gifExport('Cut GIF', 'Cut_$stem', clip.cut(_cut.start.round(), _cut.end.round()));
    }
  }

  _Export _gifExport(String title, String filename, GifClip edited) {
    final bytes = edited.encode();
    return _Export(
      title: title,
      filename: filename,
      mime: 'image/gif',
      bytes: bytes,
      width: edited.width,
      height: edited.height,
      frames: edited.frameCount,
      delayMs: edited.delayMs,
      still: bytes,
    );
  }

  String _fileStem(String name) {
    final base = name.split('/').last;
    final dot = base.lastIndexOf('.');
    return dot <= 0 ? base : base.substring(0, dot);
  }

  String _prefixedName(String name) => name.split('/').last;

  void _resetResize() {
    final clip = _clip;
    if (clip == null) return;
    setState(() {
      _width = _baseWidth.toDouble();
      _height = _baseHeight.toDouble();
      _preview = _makePreview(clip);
    });
  }

  void _setWidth(double value) {
    final clip = _clip;
    setState(() {
      _width = value;
      if (_lock && _baseWidth > 0) {
        _height = (value * _baseHeight / _baseWidth).clamp(_axisMin(_baseHeight), _axisMax(_baseHeight));
      }
      if (clip != null) _preview = _makePreview(clip);
    });
  }

  void _setHeight(double value) {
    final clip = _clip;
    setState(() {
      _height = value;
      if (_lock && _baseHeight > 0) {
        _width = (value * _baseWidth / _baseHeight).clamp(_axisMin(_baseWidth), _axisMax(_baseWidth));
      }
      if (clip != null) _preview = _makePreview(clip);
    });
  }

  String _sourceInfo(GifClip clip) {
    final rate = clip.fps;
    final fps = rate >= 10 ? rate.toStringAsFixed(0) : rate.toStringAsFixed(1);
    return '${byteLabel(_originalBytes!.length)} · ${clip.width}×${clip.height} · $fps FPS · ${clip.frameCount}프레임';
  }

  @override
  Widget build(BuildContext context) {
    final clip = _clip;
    final open = clip != null && _originalBytes != null;
    return FeatureScaffold(
      title: 'GIF Editor',
      subtitle: 'GIF 편집기 · GIF 하나를 올리고 오른쪽 도구로 편집해요',
      emoji: '🎬',
      accent: const Color(0xFFFFC2D4),
      scrollable: false,
      showHeader: !open,
      child: open
          ? _editor(clip)
          : ListView(
              children: [
                NlpRequestBar(
                  tool: 'gif-editor',
                  hint: '예: 가로 240으로 줄이고 빠르게 재생해 줘',
                  ask: askGifEditor,
                  onAnswer: _onNlp,
                ),
                const SizedBox(height: 12),
                UploadDropZone(
                  title: 'GIF를 여기에 놓아요',
                  subtitle: '드래그하거나 Select File로 고를 수 있어요',
                  buttonLabel: 'Select File',
                  onPicked: _load,
                  accent: const Color(0xFFFFC2D4),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: GoogleFonts.notoSansKr(color: AppTheme.coral, fontWeight: FontWeight.w700)),
                ],
              ],
            ),
    );
  }

  Widget _editor(GifClip clip) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 700;
        final left = ListView(
          children: [
            if (_originalOpen) _originalCard(clip) else _collapsedOriginal(),
            if (_busy || _export != null) ...[
              const SizedBox(height: 12),
              _resultCard(),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: GoogleFonts.notoSansKr(color: AppTheme.coral, fontWeight: FontWeight.w700)),
            ],
          ],
        );
        final tools = ListView(children: [_toolsCard(clip)]);
        if (!wide) {
          return ListView(
            children: [
              if (_originalOpen) _originalCard(clip) else _collapsedOriginal(),
              if (_busy || _export != null) ...[
                const SizedBox(height: 12),
                _resultCard(),
              ],
              const SizedBox(height: 12),
              _toolsCard(clip),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: GoogleFonts.notoSansKr(color: AppTheme.coral, fontWeight: FontWeight.w700)),
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: left),
            const SizedBox(width: 12),
            Expanded(child: tools),
          ],
        );
      },
    );
  }

  Widget _collapsedOriginal() {
    return SectionCard(
      color: const Color(0xFFFFF7FB),
      child: Row(
        children: [
          _panelToggle(),
          const SizedBox(width: 8),
          Text('Original GIF', style: GoogleFonts.fredoka(fontSize: 22, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _panelToggle() {
    return IconButton(
      tooltip: _originalOpen ? '패널 닫기' : '패널 열기',
      onPressed: () => setState(() => _originalOpen = !_originalOpen),
      icon: Icon(_originalOpen ? Icons.expand_less_rounded : Icons.expand_more_rounded),
    );
  }

  Widget _originalCard(GifClip clip) {
    return SectionCard(
      color: const Color(0xFFFFF7FB),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _panelToggle(),
              Expanded(child: Text('Original GIF', style: GoogleFonts.fredoka(fontSize: 22, fontWeight: FontWeight.w700))),
              IconButton(
                tooltip: '다운로드',
                onPressed: () => downloadFile(
                  context,
                  bytes: _originalBytes!,
                  filename: clip.name,
                  mimeType: 'image/gif',
                ),
                icon: const Icon(Icons.download_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final sideBySide = constraints.maxWidth >= 460;
              final original = _frameBox(_originalBytes!);
              final edited = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Edited GIF', style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  _frameBox(_preview),
                ],
              );
              if (!sideBySide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [original, const SizedBox(height: 12), edited],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: original),
                  const SizedBox(width: 12),
                  Expanded(child: edited),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          Text(clip.name, style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w800)),
          Text(_sourceInfo(clip), style: GoogleFonts.notoSansKr(color: AppTheme.muted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('임시 미리보기 · Go! 를 누르면 결과 패널이 생겨요', style: GoogleFonts.notoSansKr(color: AppTheme.muted, fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _frameBox(Uint8List? bytes) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: ColoredBox(
        color: Colors.white,
        child: SizedBox(
          height: 220,
          width: double.infinity,
          child: bytes == null ? const Center(child: Icon(Icons.image_outlined)) : Image.memory(bytes, fit: BoxFit.contain),
        ),
      ),
    );
  }

  Widget _resultCard() {
    final export = _export;
    final preview = export?.still ?? _preview;
    return SectionCard(
      color: const Color(0xFFE7FFF4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(export?.title ?? '변환 중', style: GoogleFonts.fredoka(fontSize: 22, fontWeight: FontWeight.w700)),
              ),
              if (export != null)
                IconButton(
                  tooltip: '다운로드',
                  onPressed: () => downloadFile(
                    context,
                    bytes: export.bytes,
                    filename: export.filename,
                    mimeType: export.mime,
                  ),
                  icon: const Icon(Icons.download_rounded),
                ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: _busy ? _progress : 1, minHeight: 8, borderRadius: BorderRadius.circular(8)),
          const SizedBox(height: 8),
          if (preview != null) _frameBox(preview),
          if (export != null) ...[
            const SizedBox(height: 8),
            Text(export.filename, style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w800)),
            Text(export.info, style: GoogleFonts.notoSansKr(color: AppTheme.muted, fontWeight: FontWeight.w600)),
          ],
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
            children: [for (final tool in GifTool.values) _toolButton(tool)],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy ? null : _clearFile,
            icon: const Icon(Icons.folder_open_rounded),
            label: const Text('Choose Another File'),
          ),
          const SizedBox(height: 14),
          _panel(clip),
        ],
      ),
    );
  }

  Widget _toolButton(GifTool tool) {
    final selected = _tool == tool;
    return ChoiceChip(
      avatar: Icon(_toolIcons[tool], size: 18, color: AppTheme.ink),
      label: Text(_toolLabels[tool]!),
      selected: selected,
      onSelected: (_) => _tune(() => _tool = tool),
    );
  }

  Widget _panel(GifClip clip) {
    return switch (_tool) {
      GifTool.resize => _resizePanel(),
      GifTool.crop => _cropPanel(),
      GifTool.downsizing => _downsizePanel(),
      GifTool.convert => _actionRow(
          clip.frameCount > 1
              ? (kIsWeb ? '여러 프레임이라 MP4로 녹화해요. 브라우저가 MP4를 못 만들면 WebM으로 받아요.' : '여러 프레임 MP4는 브라우저에서만 만들 수 있어요.')
              : '한 장짜리 이미지라 JPG로 저장해요.',
        ),
      GifTool.rotate => _rotatePanel(),
      GifTool.optimize => _actionRow('색 수를 정리해 크기는 유지한 채로 용량을 줄여요.'),
      GifTool.reverse => _actionRow('프레임 순서를 뒤집어 역재생 GIF로 저장해요.'),
      GifTool.speed => _speedPanel(clip),
      GifTool.cut => _cutPanel(clip),
    };
  }

  Widget _resizePanel() {
    final minW = _axisMin(_baseWidth);
    final maxW = _axisMax(_baseWidth);
    final minH = _axisMin(_baseHeight);
    final maxH = _axisMax(_baseHeight);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.arrow_right_alt_rounded, color: AppTheme.coral),
            Text(' X ${_width.round()}', style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w800)),
            const Spacer(),
            IconButton(
              tooltip: _lock ? '비율 잠금' : '비율 풀기',
              onPressed: () => setState(() => _lock = !_lock),
              icon: Icon(_lock ? Icons.lock_rounded : Icons.lock_open_rounded, color: AppTheme.coral),
            ),
            const Spacer(),
            const Icon(Icons.arrow_upward_rounded, color: AppTheme.coral),
            Text(' Y ${_height.round()}', style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w800)),
          ],
        ),
        Slider(value: _width.clamp(minW, maxW), min: minW, max: maxW, onChanged: _busy ? null : _setWidth),
        Slider(value: _height.clamp(minH, maxH), min: minH, max: maxH, onChanged: _busy ? null : _setHeight),
        Text('최소 5% · 최대 300%', style: GoogleFonts.notoSansKr(color: AppTheme.muted, fontWeight: FontWeight.w700, fontSize: 12)),
        const SizedBox(height: 8),
        Row(
          children: [
            OutlinedButton(onPressed: _busy ? null : _resetResize, child: const Text('Back')),
            const SizedBox(width: 8),
            FilledButton(onPressed: _busy ? null : _go, child: Text(_busy ? '...' : 'Go!')),
          ],
        ),
      ],
    );
  }

  Widget _cropPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('비율', style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final ratio in _cropRatios)
              ChoiceChip(
                label: Text(ratio.$1),
                selected: (_cropRatio - ratio.$2).abs() < 0.01,
                onSelected: (_) => _tune(() => _cropRatio = ratio.$2),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('단색으로 채우기'),
              selected: !_cropCover,
              onSelected: (_) => _tune(() => _cropCover = false),
            ),
            ChoiceChip(
              label: const Text('확대하여 채우기'),
              selected: _cropCover,
              onSelected: (_) => _tune(() => _cropCover = true),
            ),
          ],
        ),
        if (!_cropCover) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (var i = 0; i < _padColors.length; i++)
                ChoiceChip(
                  label: Text(_padColors[i].$1),
                  selected: _padIndex == i,
                  onSelected: (_) => _tune(() => _padIndex = i),
                ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        _goButton(),
      ],
    );
  }

  Widget _downsizePanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('사이즈 축소'),
          value: _shrinkSize,
          onChanged: (value) => _tune(() => _shrinkSize = value ?? false),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('프레임 삭제'),
          value: _dropFrames,
          onChanged: (value) => _tune(() => _dropFrames = value ?? false),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('해상도 낮추기'),
          value: _lowerResolution,
          onChanged: (value) => _tune(() => _lowerResolution = value ?? false),
        ),
        _goButton(),
      ],
    );
  }

  Widget _rotatePanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final angle in [90, 180, 270])
              ChoiceChip(
                avatar: const Icon(Icons.rotate_right_rounded, size: 18),
                label: Text('$angle°'),
                selected: _rotate == angle,
                onSelected: (_) => _tune(() => _rotate = angle),
              ),
            FilterChip(
              avatar: const Icon(Icons.swap_horiz_rounded, size: 18),
              label: const Text('좌우 뒤집기'),
              selected: _flipH,
              onSelected: (value) => _tune(() => _flipH = value),
            ),
            FilterChip(
              avatar: const Icon(Icons.swap_vert_rounded, size: 18),
              label: const Text('상하 뒤집기'),
              selected: _flipV,
              onSelected: (value) => _tune(() => _flipV = value),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _goButton(),
      ],
    );
  }

  Widget _speedPanel(GifClip clip) {
    final fps = (clip.fps * _speed).clamp(0.1, 60);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('재생 ${_speed.toStringAsFixed(2)}배 · ${fps.toStringAsFixed(fps >= 10 ? 0 : 1)} FPS', style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w800)),
        Slider(
          value: _speed.clamp(0.25, 4),
          min: 0.25,
          max: 4,
          divisions: 15,
          label: '${_speed.toStringAsFixed(2)}x',
          onChanged: _busy ? null : (value) => _tune(() => _speed = value),
        ),
        _goButton(),
      ],
    );
  }

  Widget _cutPanel(GifClip clip) {
    final maxFrame = math.max(0, clip.frameCount - 1).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('남길 구간 ${_cut.start.round()}–${_cut.end.round()}프레임', style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w800)),
        RangeSlider(
          values: RangeValues(_cut.start.clamp(0, maxFrame), _cut.end.clamp(0, maxFrame)),
          min: 0,
          max: maxFrame == 0 ? 1 : maxFrame,
          divisions: clip.frameCount > 1 ? clip.frameCount - 1 : null,
          onChanged: clip.frameCount < 2 || _busy ? null : (value) => _tune(() => _cut = value),
        ),
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
      child: FilledButton(onPressed: _busy ? null : _go, child: Text(_busy ? '...' : 'Go!')),
    );
  }
}
