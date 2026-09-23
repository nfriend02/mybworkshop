import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/utils/capture_png.dart';
import '../../../shared/utils/download_file.dart';
import '../../../shared/utils/image_sniff.dart';
import '../../../shared/utils/pick_files.dart';
import '../../../shared/utils/record_job.dart';
import '../../../shared/widgets/feature_scaffold.dart';
import '../../../shared/widgets/go_button.dart';
import '../../../shared/widgets/nlp_request_bar.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/upload_drop_zone.dart';
import '../../../shared/widgets/waiting_job_tile.dart';
import '../domain/gemini_bridge.dart';
import '../domain/meme_captions.dart';

class MemeGeneratorView extends StatefulWidget {
  const MemeGeneratorView({super.key});

  @override
  State<MemeGeneratorView> createState() => _MemeGeneratorViewState();
}

class _MemeGeneratorViewState extends State<MemeGeneratorView> {
  final _top = TextEditingController();
  final _bottom = TextEditingController();
  final _preview = GlobalKey();
  PickedBytes? _photo;
  Uint8List? _geminiImage;
  var _busy = false;
  var _started = false;
  String? _note;

  @override
  void dispose() {
    _top.dispose();
    _bottom.dispose();
    super.dispose();
  }

  Future<void> _load(List<PickedBytes> files) async {
    final file = files.first;
    final kind = imageKindOf(file.bytes, name: file.name, mimeType: file.mimeType);
    if (kind == ImageKind.heic || kind == ImageKind.unknown) {
      setState(() => _note = kind == ImageKind.heic ? heicUploadMessage : '이미지를 찾지 못했어요. PNG, JPG, GIF, WEBP를 올려 주세요');
      return;
    }
    setState(() {
      _photo = PickedBytes(name: ensureImageName(file.name, kind), bytes: file.bytes, mimeType: file.mimeType);
      _geminiImage = null;
      _started = false;
      _note = null;
    });
  }

  Future<void> _make() async {
    final photo = _photo;
    final caption = _captionText();
    if (photo == null || caption.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _started = true;
    });
    try {
      final answer = await askMeme(request: caption, image: photo.bytes, filename: photo.name);
      if (!mounted) return;
      _applyCaptions(answer.text);
      setState(() {
        _geminiImage = answer.hasImage ? answer.imageBytes : null;
        _note = answer.text.trim().isEmpty ? null : answer.text.trim();
      });
      await recordJob(
        context,
        tool: 'meme-generator',
        title: '밈',
        detail: caption,
        extra: {'request': caption, 'result': answer.text, 'status': 'done'},
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _captionText() {
    final top = _top.text.trim();
    final bottom = _bottom.text.trim();
    if (top.isEmpty) return bottom;
    if (bottom.isEmpty) return top;
    return '$top\n$bottom';
  }

  void _applyCaptions(String text) {
    final captions = parseMemeCaptions(text);
    if (captions.top != null) _top.text = captions.top!;
    if (captions.bottom != null) _bottom.text = captions.bottom!;
  }

  Future<void> _download() async {
    if (_geminiImage != null) {
      await downloadFile(context, bytes: _geminiImage!, filename: 'meme.png', mimeType: 'image/png');
      return;
    }
    final bytes = await capturePng(_preview);
    if (bytes == null || !mounted) return;
    await downloadFile(context, bytes: bytes, filename: 'meme.png', mimeType: 'image/png');
  }

  @override
  Widget build(BuildContext context) {
    final top = _top.text.trim();
    final bottom = _bottom.text.trim();
    final captionReady = top.isNotEmpty || bottom.isNotEmpty;
    return FeatureScaffold(
      title: '밈 생성',
      subtitle: '사진과 문구를 올리면 밈으로 붙여 줘요',
      emoji: '😂',
      accent: const Color(0xFFFFE0F0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NlpRequestBar(
            tool: 'meme-generator',
            hint: '예: 더 엉뚱한 자막으로 바꿔 줘',
            ask: (request) => askMeme(
              request: _captionText().isEmpty ? request : '${_captionText()}\n$request',
              image: _photo?.bytes,
              filename: _photo?.name ?? 'meme.png',
            ),
            onAnswer: (answer) async {
              _applyCaptions(answer.text);
              setState(() {
                if (answer.text.trim().isNotEmpty) _note = answer.text.trim();
              });
            },
          ),
          const SizedBox(height: 12),
          UploadDropZone(
            title: '밈에 쓸 사진을 놓아요',
            subtitle: '문구를 적고 GO를 누르면 밈이 됩니다',
            buttonLabel: 'Select File',
            onPicked: _load,
            accent: const Color(0xFFFFE0F0),
            sideAction: GoButton(
              busy: _busy,
              onPressed: _photo == null || !captionReady ? null : _make,
            ),
          ),
          if (_photo != null && !_started) ...[
            const SizedBox(height: 12),
            WaitingJobTile(name: _photo!.name, preview: _photo!.bytes, progress: 0),
          ],
          if (_photo != null) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _top,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: '윗줄', hintText: '상단 자막'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _bottom,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: '아랫줄', hintText: '하단 자막'),
            ),
          ],
          if (_started && _photo != null) ...[
            const SizedBox(height: 12),
            SectionCard(
              child: Column(
                children: [
                  RepaintBoundary(
                    key: _preview,
                    child: ColoredBox(
                      color: Colors.white,
                      child: Column(
                        children: [
                          if (top.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(top, textAlign: TextAlign.center, style: GoogleFonts.notoSansKr(fontSize: 22, fontWeight: FontWeight.w900)),
                            ),
                          Image.memory(_geminiImage ?? _photo!.bytes, height: 240, fit: BoxFit.contain),
                          if (bottom.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(bottom, textAlign: TextAlign.center, style: GoogleFonts.notoSansKr(fontSize: 22, fontWeight: FontWeight.w900)),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  WaitingJobTile(
                    name: '밈',
                    preview: _geminiImage ?? _photo!.bytes,
                    progress: _busy ? null : 1,
                    trailing: IconButton(
                      tooltip: '다운로드',
                      onPressed: _download,
                      icon: const Icon(Icons.download_rounded),
                    ),
                  ),
                  if (_note != null) ...[
                    const SizedBox(height: 8),
                    Text(_note!, style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w600)),
                  ],
                ],
              ),
            ),
          ],
          if (_photo == null && _note != null) ...[
            const SizedBox(height: 8),
            Text(_note!, style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w700)),
          ],
        ],
      ),
    );
  }
}
