import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../shared/utils/capture_png.dart';
import '../../shared/utils/pick_files.dart';
import '../../shared/utils/record_job.dart';
import '../../shared/utils/save_bytes.dart';
import '../../shared/widgets/feature_scaffold.dart';

class MemeGeneratorPage extends StatefulWidget {
  const MemeGeneratorPage({super.key});

  @override
  State<MemeGeneratorPage> createState() => _MemeGeneratorPageState();
}

class _MemeGeneratorPageState extends State<MemeGeneratorPage> {
  final _top = TextEditingController(text: '워크샵 시작');
  final _bottom = TextEditingController(text: '파스텔은 진지하다');
  final _boundary = GlobalKey();
  Uint8List? _photo;

  @override
  void dispose() {
    _top.dispose();
    _bottom.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final picked = await pickWorkshopFiles(type: FileType.image);
    if (!mounted) return;
    setState(() => _photo = picked.isEmpty ? null : picked.first.bytes);
  }

  Future<void> _save() async {
    final png = await capturePng(_boundary);
    if (png == null || !mounted) return;
    await saveBytes(bytes: png, filename: 'meme.png', mimeType: 'image/png');
    if (!mounted) return;
    await recordJob(
      context,
      tool: 'meme',
      title: '${_top.text} / ${_bottom.text}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return FeatureScaffold(
      title: '밈 생성',
      subtitle: '위아래 자막을 올려 한 장으로 저장해요',
      emoji: '😂',
      accent: const Color(0xFFFFE0F0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _top,
            decoration: const InputDecoration(labelText: '위 자막'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _bottom,
            decoration: const InputDecoration(labelText: '아래 자막'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: _pick, child: const Text('배경 이미지')),
          const SizedBox(height: 12),
          Center(
            child: RepaintBoundary(
              key: _boundary,
              child: SizedBox(
                width: 320,
                height: 320,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_photo != null)
                      Image.memory(_photo!, fit: BoxFit.cover)
                    else
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFFFC2D4), Color(0xFFD4EFFF)],
                          ),
                        ),
                      ),
                    Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: _MemeText(_top.text),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: _MemeText(_bottom.text),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: _save, child: const Text('밈 저장')),
        ],
      ),
    );
  }
}

class _MemeText extends StatelessWidget {
  const _MemeText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.notoSansKr(
      fontSize: 26,
      fontWeight: FontWeight.w900,
      color: Colors.white,
      height: 1.1,
    );
    return Stack(
      children: [
        Text(
          text,
          textAlign: TextAlign.center,
          style: style.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 5
              ..color = const Color(0xFF3A3158),
          ),
        ),
        Text(text, textAlign: TextAlign.center, style: style),
      ],
    );
  }
}
