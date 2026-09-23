import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme/app_theme.dart';
import '../../features/markdown_presentation/domain/slide_parser.dart';
import '../../shared/utils/record_job.dart';
import '../../shared/widgets/feature_scaffold.dart';

const _sampleMarkdown = '''
# 나의 AI 워크샵
밝고 즐거운 파스텔 도구 모음

# GIF와 이미지
- 프레임을 이어 GIF로
- 너비만 지정해 리사이즈

# 발표는 제목마다
마크다운 헤딩이 한 장이 됩니다
''';

class MarkdownPresentationPage extends StatefulWidget {
  const MarkdownPresentationPage({super.key});

  @override
  State<MarkdownPresentationPage> createState() =>
      _MarkdownPresentationPageState();
}

class _MarkdownPresentationPageState extends State<MarkdownPresentationPage> {
  final _markdown = TextEditingController(text: _sampleMarkdown);
  List<Slide> _slides = parseMarkdownSlides(_sampleMarkdown);
  int _index = 0;

  @override
  void dispose() {
    _markdown.dispose();
    super.dispose();
  }

  void _rebuild() {
    final slides = parseMarkdownSlides(_markdown.text);
    setState(() {
      _slides = slides;
      _index = _index.clamp(0, slides.isEmpty ? 0 : slides.length - 1);
    });
  }

  void _step(int delta) {
    if (_slides.isEmpty) return;
    setState(() {
      _index = (_index + delta).clamp(0, _slides.length - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides.isEmpty ? null : _slides[_index];
    return FeatureScaffold(
      title: '마크다운 발표',
      subtitle: '제목(#)마다 슬라이드 한 장',
      emoji: '📽️',
      accent: const Color(0xFFFFF0C9),
      scrollable: false,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.arrowRight): () => _step(1),
          const SingleActivator(LogicalKeyboardKey.arrowLeft): () => _step(-1),
        },
        child: Focus(
          autofocus: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: TextField(
                  controller: _markdown,
                  maxLines: null,
                  expands: true,
                  decoration: const InputDecoration(labelText: '마크다운'),
                  onChanged: (_) => _rebuild(),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.card(tint: AppTheme.butter),
                  child: slide == null
                      ? const Text('슬라이드가 없어요')
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              slide.title,
                              style: GoogleFonts.fredoka(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                height: 1.05,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: SingleChildScrollView(
                                child: Text(
                                  slide.body,
                                  style: GoogleFonts.notoSansKr(
                                    fontSize: 16,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ),
                            Text('${_index + 1} / ${_slides.length}'),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: _index > 0 ? () => _step(-1) : null,
                    child: const Text('이전'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _index < _slides.length - 1 ? () => _step(1) : null,
                    child: const Text('다음'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: slide == null
                        ? null
                        : () => recordJob(
                              context,
                              tool: 'slides',
                              title: slide.title,
                              detail: '${_slides.length}장',
                            ),
                    child: const Text('현재 장 기록'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
