import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_theme.dart';
import '../../../shared/api/gemini_client.dart';
import '../../../shared/api/nlp_action.dart';
import '../../../shared/utils/capture_png.dart';
import '../../../shared/utils/download_file.dart';
import '../../../shared/utils/pick_files.dart';
import '../../../shared/utils/record_job.dart';
import '../../../shared/widgets/feature_scaffold.dart';
import '../../../shared/widgets/go_button.dart';
import '../../../shared/widgets/nlp_request_bar.dart';
import '../../../shared/widgets/scroll_paged_list.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/upload_drop_zone.dart';
import '../../../shared/widgets/waiting_job_tile.dart';
import '../domain/gemini_bridge.dart';
import '../domain/slide_parser.dart';

const _themes = {
  '파스텔': Color(0xFFFFE4EE),
  '민트': Color(0xFFD9F8EA),
  '버터': Color(0xFFFFF3C4),
  '라벤더': Color(0xFFE4D7FF),
  '스카이': Color(0xFFD4EFFF),
};

class MarkdownPresentationView extends StatefulWidget {
  const MarkdownPresentationView({super.key});

  @override
  State<MarkdownPresentationView> createState() => _MarkdownPresentationViewState();
}

class _MarkdownPresentationViewState extends State<MarkdownPresentationView> {
  final _preview = GlobalKey();
  Uint8List? _fileBytes;
  String? _fileName;
  List<Slide> _slides = const [];
  var _index = 0;
  var _busy = false;
  var _started = false;
  String _theme = '파스텔';

  Future<void> _onNlp(GeminiAnswer answer) async {
    final action = NlpAction.tryParse(answer.text);
    final theme = action?.theme;
    if (theme != null && _themes.containsKey(theme)) {
      setState(() => _theme = theme);
    }
  }

  Future<void> _load(List<PickedBytes> files) async {
    final file = files.first;
    setState(() {
      _fileBytes = file.bytes;
      _fileName = file.name;
      _slides = const [];
      _index = 0;
      _started = false;
    });
  }

  Future<void> _go() async {
    final bytes = _fileBytes;
    final name = _fileName;
    if (bytes == null || name == null || _busy) return;
    setState(() => _busy = true);
    final markdown = utf8.decode(bytes, allowMalformed: true);
    final slides = parseMarkdownSlides(markdown);
    if (!mounted) return;
    setState(() {
      _slides = slides;
      _index = 0;
      _started = true;
      _busy = false;
    });
    await recordJob(
      context,
      tool: 'markdown-presentation',
      title: name,
      detail: '${slides.length}장',
      extra: {'status': 'done'},
    );
  }

  Future<void> _download() async {
    final bytes = await capturePng(_preview);
    if (bytes == null || !mounted) return;
    await downloadFile(context, bytes: bytes, filename: 'slide_${_index + 1}.png', mimeType: 'image/png');
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides.isEmpty ? null : _slides[_index];
    return FeatureScaffold(
      title: '마크다운 발표',
      subtitle: '문서를 올리면 테마에 맞춰 슬라이드가 됩니다',
      emoji: '📽️',
      accent: const Color(0xFFFFF0C9),
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NlpRequestBar(
            tool: 'markdown-presentation',
            hint: '예: 민트 테마로 바꿔 줘',
            ask: askSlides,
            onAnswer: _onNlp,
          ),
          const SizedBox(height: 8),
          UploadDropZone(
            title: '마크다운을 놓아요',
            subtitle: '# 제목으로 슬라이드가 나뉘어요. GO를 누르면 만들어요',
            buttonLabel: 'Select File',
            onPicked: _load,
            accent: const Color(0xFFFFF0C9),
            sideAction: GoButton(
              busy: _busy,
              onPressed: _fileBytes == null ? null : _go,
            ),
          ),
          if (_fileName != null && !_started) ...[
            const SizedBox(height: 12),
            WaitingJobTile(name: _fileName!, progress: 0),
          ],
          if (_started && slide != null) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final theme in _themes.keys)
                  ChoiceChip(
                    label: Text(theme),
                    selected: _theme == theme,
                    onSelected: (_) => setState(() => _theme = theme),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            RepaintBoundary(
              key: _preview,
              child: SectionCard(
                color: _themes[_theme]!,
                child: SizedBox(
                  height: 220,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(slide.title, style: GoogleFonts.fredoka(fontSize: 32, fontWeight: FontWeight.w700, color: AppTheme.ink)),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Text(slide.body, style: GoogleFonts.notoSansKr(fontSize: 16, fontWeight: FontWeight.w600, height: 1.4)),
                      ),
                      Text('${_index + 1} / ${_slides.length}', style: GoogleFonts.notoSansKr(color: AppTheme.muted, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton(onPressed: _index == 0 ? null : () => setState(() => _index -= 1), child: const Text('이전')),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _index >= _slides.length - 1 ? null : () => setState(() => _index += 1),
                  child: const Text('다음'),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _download,
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('다운로드'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: ScrollPagedList<Slide>(
                items: _slides,
                itemBuilder: (context, item, index) => ListTile(
                  selected: index == _index,
                  title: Text(item.title),
                  onTap: () => setState(() => _index = index),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
