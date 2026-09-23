import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../features/gif_generator/domain/gif_builder.dart';
import '../../shared/utils/record_job.dart';
import '../../shared/utils/save_bytes.dart';
import '../../shared/widgets/feature_scaffold.dart';

class GifGeneratorPage extends StatefulWidget {
  const GifGeneratorPage({super.key});

  @override
  State<GifGeneratorPage> createState() => _GifGeneratorPageState();
}

class _GifGeneratorPageState extends State<GifGeneratorPage> {
  final _text = TextEditingController(text: 'My AI Workshop');
  int _color = 0;
  Uint8List? _gif;
  bool _busy = false;
  String? _error;

  static const _colors = <(String, int, int, int)>[
    ('핑크', 255, 194, 212),
    ('민트', 200, 242, 224),
    ('버터', 255, 241, 184),
    ('하늘', 212, 239, 255),
    ('라벤더', 228, 215, 255),
  ];

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final color = _colors[_color];
      final gif = buildCaptionGif(
        text: _text.text,
        red: color.$2,
        green: color.$3,
        blue: color.$4,
      );
      if (!mounted) return;
      setState(() => _gif = gif);
      await recordJob(
        context,
        tool: 'gif-generator',
        title: _text.text.trim(),
        detail: color.$1,
      );
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FeatureScaffold(
      title: 'GIF 생성',
      subtitle: '글자와 파스텔 배경으로 짧은 루프를 만들어요',
      emoji: '✨',
      accent: const Color(0xFFFFF1B8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _text,
            decoration: const InputDecoration(labelText: '문구'),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (var i = 0; i < _colors.length; i++)
                ChoiceChip(
                  label: Text(_colors[i].$1),
                  selected: _color == i,
                  onSelected: (_) => setState(() => _color = i),
                ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _busy ? null : _generate,
            child: Text(_busy ? '그리는 중…' : 'GIF 생성'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!),
          ],
          if (_gif != null) ...[
            const SizedBox(height: 16),
            Center(child: Image.memory(_gif!, height: 180)),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => saveBytes(
                bytes: _gif!,
                filename: 'generated.gif',
                mimeType: 'image/gif',
              ),
              child: const Text('GIF 저장'),
            ),
          ],
        ],
      ),
    );
  }
}
