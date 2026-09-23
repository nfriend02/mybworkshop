import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/text_summarizer/domain/extractive_summarizer.dart';
import '../../shared/api/api_client.dart';
import '../../shared/utils/record_job.dart';
import '../../shared/widgets/feature_scaffold.dart';

class TextSummarizerPage extends StatefulWidget {
  const TextSummarizerPage({super.key});

  @override
  State<TextSummarizerPage> createState() => _TextSummarizerPageState();
}

class _TextSummarizerPageState extends State<TextSummarizerPage> {
  final _text = TextEditingController(
    text:
        '파스텔 워크샵은 이미지를 줄이고 GIF를 만들며 QR을 그립니다. '
        '긴 글은 자주 나온 단어가 있는 문장을 골라 요약합니다. '
        '발표 자료는 마크다운 제목마다 한 장씩 넘어갑니다. '
        '아바타는 이름에서 색과 표정을 정합니다.',
  );
  double _sentences = 2;
  String _summary = '';
  String _source = '';
  bool _busy = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    setState(() => _busy = true);
    final local = ExtractiveSummarizer.summarize(
      _text.text,
      maxSentences: _sentences.round(),
    );
    final remote = await ApiClient().summarize(
      _text.text,
      sentences: _sentences.round(),
    );
    if (!mounted) return;
    setState(() {
      _summary = (remote != null && remote.trim().isNotEmpty) ? remote : local;
      _source = remote == null ? '기기 안 요약' : '/api/summarize';
      _busy = false;
    });
    await recordJob(
      context,
      tool: 'summarize',
      title: _summary,
      detail: _source,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FeatureScaffold(
      title: '텍스트 요약',
      subtitle: '핵심 문장을 고르고, 배포 환경에서는 /api도 시도해요',
      emoji: '📝',
      accent: const Color(0xFFCDECCF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _text,
            minLines: 6,
            maxLines: 10,
            decoration: const InputDecoration(labelText: '원문'),
          ),
          const SizedBox(height: 8),
          Text('문장 수 ${_sentences.round()}'),
          Slider(
            value: _sentences,
            min: 1,
            max: 5,
            divisions: 4,
            onChanged: (value) => setState(() => _sentences = value),
          ),
          FilledButton(
            onPressed: _busy ? null : _run,
            child: Text(_busy ? '요약 중…' : '요약하기'),
          ),
          if (_summary.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(_source, style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            SelectableText(_summary, style: GoogleFonts.notoSansKr(height: 1.5)),
          ],
        ],
      ),
    );
  }
}
