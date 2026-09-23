import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/api/gemini_client.dart';
import '../../../shared/utils/record_job.dart';
import '../../../shared/widgets/feature_scaffold.dart';
import '../../../shared/widgets/nlp_request_bar.dart';
import '../../../shared/widgets/section_card.dart';
import '../domain/extractive_summarizer.dart';
import '../domain/gemini_bridge.dart';

const _languages = ['한국어', 'English', '日本語', '中文', 'Español', 'Français'];

class TextSummarizerView extends StatefulWidget {
  const TextSummarizerView({super.key});

  @override
  State<TextSummarizerView> createState() => _TextSummarizerViewState();
}

class _TextSummarizerViewState extends State<TextSummarizerView> {
  final _source = TextEditingController();
  String _language = '한국어';
  var _translate = false;
  var _busy = false;
  String? _result;

  @override
  void dispose() {
    _source.dispose();
    super.dispose();
  }

  Future<GeminiAnswer> _ask(String request) {
    final source = _source.text.trim().isEmpty ? request : _source.text.trim();
    final prompt = request.trim().isEmpty || request.trim() == source ? source : '$source\n\n추가 요청: $request';
    return askSummarizer(request: prompt, language: _language, translate: _translate);
  }

  Future<void> _onAnswer(GeminiAnswer answer) async {
    if (answer.usedFallback && _translate) {
      setState(() => _result = answer.text);
      return;
    }
    if (answer.usedFallback && !_translate) {
      final local = ExtractiveSummarizer.summarize(_source.text);
      setState(() => _result = local.isEmpty ? answer.text : '$local\n\n${answer.text}');
      return;
    }
    setState(() => _result = answer.text);
  }

  Future<void> _run() async {
    final source = _source.text.trim();
    if (source.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      final answer = await _ask(source);
      if (!mounted) return;
      await _onAnswer(answer);
      if (!mounted) return;
      await recordJob(
        context,
        tool: 'text-summarizer',
        title: _translate ? '번역 $_language' : '요약 $_language',
        detail: _result ?? '',
        extra: {'request': source, 'result': _result ?? '', 'status': 'done'},
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FeatureScaffold(
      title: '요약/번역',
      subtitle: '글을 붙이고 언어를 고르면 Gemini가 정리해요',
      emoji: '📝',
      accent: const Color(0xFFCDECCF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NlpRequestBar(
            tool: 'text-summarizer',
            hint: '예: 더 짧게, 친구에게 말하듯 번역해 줘',
            ask: _ask,
            onAnswer: _onAnswer,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _language,
            decoration: const InputDecoration(labelText: '언어'),
            items: [for (final language in _languages) DropdownMenuItem(value: language, child: Text(language))],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _language = value);
            },
          ),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('요약')),
              ButtonSegment(value: true, label: Text('번역')),
            ],
            selected: {_translate},
            onSelectionChanged: (value) => setState(() => _translate = value.first),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _source,
            minLines: 6,
            maxLines: 12,
            decoration: const InputDecoration(hintText: '요약하거나 번역할 글을 붙여 넣어요'),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(onPressed: _busy ? null : _run, child: Text(_busy ? 'Gemini 호출 중' : '실행')),
          ),
          if (_result != null) ...[
            const SizedBox(height: 12),
            SectionCard(
              color: const Color(0xFFCDECCF),
              child: SelectableText(_result!, style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w600, height: 1.5)),
            ),
          ],
        ],
      ),
    );
  }
}
