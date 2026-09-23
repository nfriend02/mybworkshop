import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../features/image_resizer/domain/image_resizer.dart';
import '../../shared/utils/pick_files.dart';
import '../../shared/utils/record_job.dart';
import '../../shared/utils/save_bytes.dart';
import '../../shared/widgets/feature_scaffold.dart';

class ImageResizerPage extends StatefulWidget {
  const ImageResizerPage({super.key});

  @override
  State<ImageResizerPage> createState() => _ImageResizerPageState();
}

class _ImageResizerPageState extends State<ImageResizerPage> {
  Uint8List? _source;
  Uint8List? _result;
  double _width = 480;
  String? _error;
  bool _busy = false;

  Future<void> _pick() async {
    final picked = await pickWorkshopFiles(type: FileType.image);
    if (!mounted || picked.isEmpty) return;
    setState(() {
      _source = picked.first.bytes;
      _result = null;
      _error = null;
    });
  }

  Future<void> _resize() async {
    final source = _source;
    if (source == null) return;
    setState(() => _busy = true);
    try {
      final png = resizeToWidth(source, _width.round());
      if (!mounted) return;
      setState(() {
        _result = png;
        _error = null;
      });
      await recordJob(
        context,
        tool: 'image-resizer',
        title: '너비 ${_width.round()}px',
        detail: '${png.length} bytes',
      );
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return FeatureScaffold(
      title: '이미지 리사이즈',
      subtitle: '비율을 유지한 채 너비를 바꿔요',
      emoji: '🖼️',
      accent: const Color(0xFFC8F2E0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: _busy ? null : _pick,
            icon: const Icon(Icons.image_rounded),
            label: const Text('이미지 선택'),
          ),
          const SizedBox(height: 8),
          Text('너비 ${_width.round()}px'),
          Slider(
            value: _width,
            min: 64,
            max: 1600,
            onChanged: _busy ? null : (value) => setState(() => _width = value),
          ),
          FilledButton(
            onPressed: _source == null || _busy ? null : _resize,
            child: Text(_busy ? '변환 중…' : '리사이즈'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!),
          ],
          if (result != null) ...[
            const SizedBox(height: 16),
            Text('${result.length} bytes PNG'),
            const SizedBox(height: 8),
            Center(child: Image.memory(result, height: 240)),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => saveBytes(
                bytes: result,
                filename: 'resized.png',
                mimeType: 'image/png',
              ),
              child: const Text('PNG 저장'),
            ),
          ],
        ],
      ),
    );
  }
}
