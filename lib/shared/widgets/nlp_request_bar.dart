import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme/app_theme.dart';
import '../api/gemini_client.dart';
import '../config/app_config.dart';
import '../utils/record_job.dart';

/// Natural-language box wired to Gemini. Every feature screen includes one.
class NlpRequestBar extends StatefulWidget {
  const NlpRequestBar({
    super.key,
    required this.tool,
    required this.hint,
    required this.ask,
    this.onAnswer,
  });

  final String tool;
  final String hint;
  final Future<GeminiAnswer> Function(String request) ask;
  final Future<void> Function(GeminiAnswer answer)? onAnswer;

  @override
  State<NlpRequestBar> createState() => _NlpRequestBarState();
}

class _NlpRequestBarState extends State<NlpRequestBar> {
  final _controller = TextEditingController();
  var _busy = false;
  String? _answer;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final request = _controller.text.trim();
    if (request.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _answer = null;
    });
    try {
      final answer = await widget.ask(request);
      if (!mounted) return;
      setState(() => _answer = answer.text.trim().isEmpty ? '응답이 비어 있어요.' : answer.text.trim());
      await recordJob(
        context,
        tool: widget.tool,
        title: '자연어 요청',
        detail: answer.text,
        extra: {'request': request, 'result': answer.text, 'status': 'done'},
        notify: false,
      );
      if (!mounted) return;
      await widget.onAnswer?.call(answer);
    } catch (error) {
      if (!mounted) return;
      setState(() => _answer = '요청을 처리하지 못했어요. $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ready = AppConfig.hasGeminiKey;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F6),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.peach),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Text('✨', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '자연어로 부탁하기',
                    style: GoogleFonts.fredoka(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: ready ? AppTheme.mint : AppTheme.butter,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    ready ? 'Gemini 연결됨' : '키 대기',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.ink,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _controller,
              minLines: 2,
              maxLines: 4,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(hintText: widget.hint),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _busy ? null : _submit,
                icon: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.auto_awesome_rounded, size: 18),
                label: Text(_busy ? 'Gemini 생각 중' : '요청하기'),
              ),
            ),
            if (_answer != null) ...[
              const SizedBox(height: 8),
              Text(
                _answer!,
                style: GoogleFonts.notoSansKr(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.ink,
                  height: 1.45,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
