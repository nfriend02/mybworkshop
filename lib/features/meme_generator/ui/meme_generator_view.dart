import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/utils/capture_png.dart';
import '../../../shared/utils/download_file.dart';
import '../../../shared/utils/pick_files.dart';
import '../../../shared/utils/record_job.dart';
import '../../../shared/widgets/feature_scaffold.dart';
import '../../../shared/widgets/nlp_request_bar.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/upload_drop_zone.dart';
import '../domain/gemini_bridge.dart';

class MemeGeneratorView extends StatefulWidget {
  const MemeGeneratorView({super.key});

  @override
  State<MemeGeneratorView> createState() => _MemeGeneratorViewState();
}

class _MemeGeneratorViewState extends State<MemeGeneratorView> {
  final _caption = TextEditingController();
  final _preview = GlobalKey();
  PickedBytes? _photo;
  Uint8List? _geminiImage;
  var _busy = false;
  String? _note;

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  Future<void> _load(List<PickedBytes> files) async {
    setState(() {
      _photo = files.first;
      _geminiImage = null;
    });
  }

  Future<void> _make() async {
    final photo = _photo;
    final caption = _caption.text.trim();
    if (photo == null || caption.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      final answer = await askMeme(request: caption, image: photo.bytes, filename: photo.name);
      if (!mounted) return;
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
    final lines = _caption.text.split('\n');
    final top = lines.first;
    final bottom = lines.length > 1 ? lines.sublist(1).join('\n') : '';
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
              request: _caption.text.trim().isEmpty ? request : '${_caption.text}\n$request',
              image: _photo?.bytes,
              filename: _photo?.name ?? 'meme.png',
            ),
            onAnswer: (answer) async {
              setState(() {
                if (answer.hasImage) _geminiImage = answer.imageBytes;
                if (answer.text.trim().isNotEmpty) _note = answer.text.trim();
              });
            },
          ),
          const SizedBox(height: 12),
          if (_photo == null)
            UploadDropZone(
              title: '밈에 쓸 사진을 놓아요',
              subtitle: '한 줄은 위, 다음 줄은 아래에 올라가요',
              buttonLabel: 'Select File',
              onPicked: _load,
              accent: const Color(0xFFFFE0F0),
            )
          else
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
                  TextField(
                    controller: _caption,
                    minLines: 2,
                    maxLines: 4,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(hintText: '윗줄\n아랫줄'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      FilledButton(onPressed: _busy ? null : _make, child: Text(_busy ? '만드는 중' : '밈 만들기')),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: _download,
                        icon: const Icon(Icons.download_rounded),
                        label: const Text('다운로드'),
                      ),
                    ],
                  ),
                  if (_note != null) ...[
                    const SizedBox(height: 8),
                    Text(_note!, style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w600)),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
