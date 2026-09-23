import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_theme.dart';
import '../../../shared/api/gemini_client.dart';
import '../../../shared/api/nlp_action.dart';
import '../../../shared/utils/download_file.dart';
import '../../../shared/utils/image_sniff.dart';
import '../../../shared/utils/pick_files.dart';
import '../../../shared/utils/record_job.dart';
import '../../../shared/widgets/feature_scaffold.dart';
import '../../../shared/widgets/go_button.dart';
import '../../../shared/widgets/nlp_request_bar.dart';
import '../../../shared/widgets/scroll_paged_list.dart';
import '../../../shared/widgets/upload_drop_zone.dart';
import '../../../shared/widgets/waiting_job_tile.dart';
import '../../document_compressor/domain/zip_compressor.dart';
import '../domain/aspect_fit.dart';
import '../domain/gemini_bridge.dart';

class _Item {
  _Item({required this.name, required this.source});

  final String name;
  final Uint8List source;
  double progress = 0;
  Uint8List? output;
  String? error;
}

class ImageResizerView extends StatefulWidget {
  const ImageResizerView({super.key});

  @override
  State<ImageResizerView> createState() => _ImageResizerViewState();
}

class _ImageResizerViewState extends State<ImageResizerView> {
  AspectChoice _ratio = kAspectChoices.first;
  FitMode _mode = FitMode.padding;
  final _width = TextEditingController(text: '1080');
  final _height = TextEditingController(text: '1080');
  final List<_Item> _items = [];
  var _busy = false;
  var _started = false;
  String? _notice;

  @override
  void dispose() {
    _width.dispose();
    _height.dispose();
    super.dispose();
  }

  Future<void> _onNlp(GeminiAnswer answer) async {
    final action = NlpAction.tryParse(answer.text);
    if (action == null) return;
    final ratio = kAspectChoices.where((item) => item.label == action.ratio).firstOrNull;
    final custom = RegExp(r'(\d+(?:\.\d+)?)\s*:\s*(\d+(?:\.\d+)?)').firstMatch(action.ratio ?? '');
    setState(() {
      if (ratio != null && ratio.label != 'Custom') {
        _ratio = ratio;
      } else if (custom != null) {
        final width = double.tryParse(custom.group(1)!);
        final height = double.tryParse(custom.group(2)!);
        if (width != null && height != null && width > 0 && height > 0) {
          _ratio = kAspectChoices.last;
          _width.text = (width * 100).round().toString();
          _height.text = (height * 100).round().toString();
        }
      }
      if (action.mode == 'crop') _mode = FitMode.crop;
      if (action.mode == 'padding') _mode = FitMode.padding;
    });
  }

  Future<void> _load(List<PickedBytes> files) async {
    final expanded = <_Item>[];
    final notes = <String>[];
    for (final file in files) {
      if (isZipPayload(file.bytes, file.name)) {
        final images = unzipImages(file.bytes);
        if (images.isEmpty) {
          notes.add('ZIP 안에서 이미지를 찾지 못했어요');
        }
        for (final image in images) {
          expanded.add(_Item(name: image.name, source: image.bytes));
        }
        continue;
      }
      final kind = imageKindOf(file.bytes, name: file.name, mimeType: file.mimeType);
      if (kind == ImageKind.heic) {
        notes.add(heicUploadMessage);
        continue;
      }
      if (kind == ImageKind.unknown) {
        notes.add('이미지를 찾지 못했어요. PNG, JPG, GIF, WEBP를 올려 주세요');
        continue;
      }
      expanded.add(_Item(name: ensureImageName(file.name, kind), source: file.bytes));
    }
    if (expanded.isEmpty) {
      setState(() {
        _notice = notes.isEmpty ? '이미지를 찾지 못했어요. PNG, JPG, GIF, WEBP를 올려 주세요' : notes.join('\n');
        _items.clear();
        _started = false;
      });
      return;
    }
    setState(() {
      _notice = notes.isEmpty ? null : notes.join('\n');
      _started = false;
      _items
        ..clear()
        ..addAll(expanded);
    });
  }

  (int, int) _box() {
    if (_ratio.isCustom) {
      final width = int.tryParse(_width.text) ?? 1080;
      final height = int.tryParse(_height.text) ?? 1080;
      return (width, height);
    }
    return boxForAspect(_ratio.widthOverHeight!);
  }

  Future<void> _run() async {
    if (_busy || _items.isEmpty) return;
    setState(() {
      _busy = true;
      _started = true;
      for (final item in _items) {
        item.progress = 0;
        item.output = null;
        item.error = null;
      }
    });
    final box = _box();
    for (final item in _items) {
      if (item.source.isEmpty) continue;
      setState(() => item.progress = 0.35);
      await Future<void>.delayed(Duration.zero);
      try {
        item.output = fitToBox(item.source, width: box.$1, height: box.$2, mode: _mode);
        item.error = null;
        item.progress = 1;
      } catch (error) {
        item.error = '$error';
        item.progress = 1;
      }
      if (mounted) setState(() {});
    }
    if (!mounted) return;
    setState(() => _busy = false);
    await recordJob(
      context,
      tool: 'image-resizer',
      title: '${_ratio.label} ${_mode.name}',
      detail: '${_items.length}장',
      extra: {'status': 'done'},
    );
  }

  Future<void> _downloadAll() async {
    final files = <String, Uint8List>{};
    for (final item in _items) {
      final output = item.output;
      if (output == null) continue;
      files['${fileStem(item.name)}.png'] = output;
    }
    if (files.isEmpty) return;
    final zip = zipFiles(files);
    if (!mounted) return;
    await downloadFile(context, bytes: zip, filename: 'resized_images.zip', mimeType: 'application/zip');
  }

  String fileStem(String name) {
    final base = name.split('/').last;
    final dot = base.lastIndexOf('.');
    return dot <= 0 ? base : base.substring(0, dot);
  }

  @override
  Widget build(BuildContext context) {
    return FeatureScaffold(
      title: '이미지 리사이즈',
      subtitle: '비율을 고르고, ZIP은 자동으로 풀려요',
      emoji: '🖼️',
      accent: AppTheme.mint,
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              children: [
                NlpRequestBar(
                  tool: 'image-resizer',
                  hint: '예: 1:1 비율로 잘라 줘',
                  ask: askImageResizer,
                  onAnswer: _onNlp,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final choice in kAspectChoices)
                      ChoiceChip(
                        label: Text(choice.label),
                        selected: _ratio == choice,
                        onSelected: (_) => setState(() => _ratio = choice),
                      ),
                  ],
                ),
                if (_ratio.isCustom) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: _width, decoration: const InputDecoration(labelText: '가로'))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: _height, decoration: const InputDecoration(labelText: '세로'))),
                    ],
                  ),
                ],
                RadioGroup<FitMode>(
                  groupValue: _mode,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _mode = value);
                  },
                  child: const Row(
                    children: [
                      Radio<FitMode>(value: FitMode.padding),
                      Text('Padding'),
                      SizedBox(width: 12),
                      Radio<FitMode>(value: FitMode.crop),
                      Text('Crop'),
                    ],
                  ),
                ),
                UploadDropZone(
                  title: '이미지나 ZIP을 놓아요',
                  subtitle: '올린 뒤 GO를 누르면 변환해요',
                  buttonLabel: 'Select Files',
                  multiple: true,
                  onPicked: _load,
                  accent: AppTheme.mint,
                  sideAction: GoButton(
                    busy: _busy,
                    onPressed: _items.isEmpty ? null : _run,
                  ),
                ),
                if (_notice != null) ...[
                  const SizedBox(height: 12),
                  Text(_notice!, style: GoogleFonts.notoSansKr(color: AppTheme.coral, fontWeight: FontWeight.w800)),
                ],
                if (_items.any((item) => item.output != null)) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.icon(
                      onPressed: _busy ? null : _downloadAll,
                      icon: const Icon(Icons.folder_zip_rounded),
                      label: const Text('전체 ZIP 다운로드'),
                    ),
                  ),
                ],
                if (!_started && _items.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  for (final item in _items) ...[
                    _tile(item, allowDownload: false),
                    const SizedBox(height: 8),
                  ],
                ],
              ],
            ),
          ),
          if (_started && _items.isNotEmpty)
            SizedBox(
              height: 280,
              child: ScrollPagedList<_Item>(
                items: _items,
                itemBuilder: (context, item, index) => _tile(item, allowDownload: true),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tile(_Item item, {required bool allowDownload}) {
    return WaitingJobTile(
      name: item.name,
      preview: item.output ?? item.source,
      progress: item.progress,
      detail: item.error,
      trailing: allowDownload && item.output != null
          ? IconButton(
              tooltip: '다운로드',
              onPressed: () => downloadFile(
                context,
                bytes: item.output!,
                filename: '${fileStem(item.name)}.png',
                mimeType: 'image/png',
              ),
              icon: const Icon(Icons.download_rounded),
            )
          : null,
    );
  }
}
