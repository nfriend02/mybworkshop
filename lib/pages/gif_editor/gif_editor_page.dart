import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../features/gif_editor/domain/gif_composer.dart';
import '../../shared/utils/pick_files.dart';
import '../../shared/utils/record_job.dart';
import '../../shared/utils/save_bytes.dart';
import '../../shared/widgets/feature_scaffold.dart';

class GifEditorPage extends StatefulWidget {
  const GifEditorPage({super.key});

  @override
  State<GifEditorPage> createState() => _GifEditorPageState();
}

class _GifEditorPageState extends State<GifEditorPage> {
  final _frames = <Uint8List>[];
  double _delay = 180;
  Uint8List? _gif;
  bool _busy = false;
  String? _error;

  Future<void> _pick() async {
    final picked = await pickWorkshopFiles(
      type: FileType.image,
      multiple: true,
    );
    if (picked.isEmpty) return;
    setState(() {
      _frames
        ..clear()
        ..addAll(picked.take(8).map((file) => file.bytes));
      _gif = null;
      _error = null;
    });
  }

  Future<void> _build() async {
    if (_frames.length < 2) {
      setState(() => _error = '이미지가 두 장 이상 필요해요');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final gif = await composeGif(_frames, _delay.round());
      if (!mounted) return;
      setState(() => _gif = gif);
      await recordJob(
        context,
        tool: 'gif-editor',
        title: '${_frames.length}프레임 GIF',
        detail: '${_delay.round()}ms',
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
      title: 'GIF 편집',
      subtitle: '이미지를 프레임으로 이어 속도를 조절해요',
      emoji: '🎬',
      accent: const Color(0xFFFFC2D4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: _busy ? null : _pick,
            icon: const Icon(Icons.photo_library_rounded),
            label: Text('이미지 선택 (${_frames.length}/8)'),
          ),
          const SizedBox(height: 12),
          Text('프레임 간격 ${_delay.round()}ms'),
          Slider(
            value: _delay,
            min: 60,
            max: 600,
            label: '${_delay.round()}ms',
            onChanged: _busy ? null : (value) => setState(() => _delay = value),
          ),
          FilledButton(
            onPressed: _busy ? null : _build,
            child: Text(_busy ? '만드는 중…' : 'GIF 만들기'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!),
          ],
          if (_gif != null) ...[
            const SizedBox(height: 16),
            Center(child: Image.memory(_gif!, height: 220)),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => saveBytes(
                bytes: _gif!,
                filename: 'workshop.gif',
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
