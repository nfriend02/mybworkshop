import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../features/document_compressor/domain/zip_compressor.dart';
import '../../shared/utils/pick_files.dart';
import '../../shared/utils/record_job.dart';
import '../../shared/utils/save_bytes.dart';
import '../../shared/widgets/feature_scaffold.dart';

class DocumentCompressorPage extends StatefulWidget {
  const DocumentCompressorPage({super.key});

  @override
  State<DocumentCompressorPage> createState() => _DocumentCompressorPageState();
}

class _DocumentCompressorPageState extends State<DocumentCompressorPage> {
  final _files = <String, Uint8List>{};
  Uint8List? _zip;
  String? _error;

  int get _original =>
      _files.values.fold<int>(0, (sum, bytes) => sum + bytes.length);

  Future<void> _pick() async {
    final picked = await pickWorkshopFiles(multiple: true);
    if (!mounted || picked.isEmpty) return;
    setState(() {
      _files
        ..clear()
        ..addEntries(picked.map((file) => MapEntry(file.name, file.bytes)));
      _zip = null;
      _error = null;
    });
  }

  Future<void> _compress() async {
    try {
      final zip = zipFiles(_files);
      setState(() {
        _zip = zip;
        _error = null;
      });
      await recordJob(
        context,
        tool: 'document-compressor',
        title: '${_files.length}개 파일 ZIP',
        detail: '$_original → ${zip.length} bytes',
      );
    } catch (e) {
      setState(() => _error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final zip = _zip;
    return FeatureScaffold(
      title: '문서 압축',
      subtitle: '고른 파일을 하나의 ZIP으로 묶어요',
      emoji: '📦',
      accent: const Color(0xFFD4EFFF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: _pick,
            icon: const Icon(Icons.attach_file_rounded),
            label: Text('파일 선택 (${_files.length})'),
          ),
          const SizedBox(height: 8),
          for (final name in _files.keys)
            Text('$name · ${_files[name]!.length} bytes'),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _files.isEmpty ? null : _compress,
            child: const Text('ZIP 만들기'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!),
          ],
          if (zip != null) ...[
            const SizedBox(height: 12),
            Text('원본 $_original bytes → ZIP ${zip.length} bytes'),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => saveBytes(
                bytes: zip,
                filename: 'workshop.zip',
                mimeType: 'application/zip',
              ),
              child: const Text('ZIP 저장'),
            ),
          ],
        ],
      ),
    );
  }
}
