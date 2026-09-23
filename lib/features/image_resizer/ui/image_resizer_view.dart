import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_theme.dart';
import '../../../shared/api/gemini_client.dart';
import '../../../shared/api/nlp_action.dart';
import '../../../shared/utils/download_file.dart';
import '../../../shared/utils/pick_files.dart';
import '../../../shared/utils/record_job.dart';
import '../../../shared/widgets/feature_scaffold.dart';
import '../../../shared/widgets/nlp_request_bar.dart';
import '../../../shared/widgets/scroll_paged_list.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/upload_drop_zone.dart';
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
    setState(() {
      if (ratio != null) _ratio = ratio;
      if (action.mode == 'crop') _mode = FitMode.crop;
      if (action.mode == 'padding') _mode = FitMode.padding;
    });
  }

  Future<void> _load(List<PickedBytes> files) async {
    final expanded = <_Item>[];
    for (final file in files) {
      if (file.name.toLowerCase().endsWith('.zip')) {
        for (final image in unzipImages(file.bytes)) {
          expanded.add(_Item(name: image.name, source: image.bytes));
        }
      } else if (isImageName(file.name)) {
        expanded.add(_Item(name: file.name, source: file.bytes));
      }
    }
    if (expanded.isEmpty) {
      setState(() => _items
        ..clear()
        ..add(_Item(name: '이미지를 찾지 못했어요', source: Uint8List(0))..error = 'PNG, JPG, GIF 또는 그 이미지들이 들어 있는 ZIP을 올려 주세요'));
      return;
    }
    setState(() {
      _items
        ..clear()
        ..addAll(expanded);
    });
    await _run();
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
    setState(() => _busy = true);
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
                  subtitle: 'ZIP은 풀려서 장마다 진행률이 보여요',
                  buttonLabel: 'Select Files',
                  multiple: true,
                  onPicked: _load,
                  accent: AppTheme.mint,
                ),
                const SizedBox(height: 12),
                if (_items.isNotEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.icon(
                      onPressed: _busy ? null : _downloadAll,
                      icon: const Icon(Icons.folder_zip_rounded),
                      label: const Text('전체 ZIP 다운로드'),
                    ),
                  ),
              ],
            ),
          ),
          if (_items.isNotEmpty)
            SizedBox(
              height: 280,
              child: ScrollPagedList<_Item>(
                items: _items,
                itemBuilder: (context, item, index) => _tile(item),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tile(_Item item) {
    return SectionCard(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          if (item.output != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.memory(item.output!, width: 56, height: 56, fit: BoxFit.cover),
            )
          else
            const SizedBox(width: 56, height: 56, child: Icon(Icons.image_rounded)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                LinearProgressIndicator(value: item.progress == 0 ? null : item.progress, minHeight: 8, borderRadius: BorderRadius.circular(8)),
                if (item.error != null)
                  Text(item.error!, style: GoogleFonts.notoSansKr(color: AppTheme.coral, fontSize: 12)),
              ],
            ),
          ),
          if (item.output != null)
            IconButton(
              tooltip: '다운로드',
              onPressed: () => downloadFile(
                context,
                bytes: item.output!,
                filename: '${fileStem(item.name)}.png',
                mimeType: 'image/png',
              ),
              icon: const Icon(Icons.download_rounded),
            ),
        ],
      ),
    );
  }
}
