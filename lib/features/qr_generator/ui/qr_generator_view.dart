import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../app/theme/app_theme.dart';
import '../../../shared/api/gemini_client.dart';
import '../../../shared/api/nlp_action.dart';
import '../../../shared/utils/capture_png.dart';
import '../../../shared/utils/download_file.dart';
import '../../../shared/utils/record_job.dart';
import '../../../shared/widgets/feature_scaffold.dart';
import '../../../shared/widgets/go_button.dart';
import '../../../shared/widgets/nlp_request_bar.dart';
import '../../../shared/widgets/section_card.dart';
import '../domain/gemini_bridge.dart';
import '../domain/qr_payload.dart';

class QrGeneratorView extends StatefulWidget {
  const QrGeneratorView({super.key});

  @override
  State<QrGeneratorView> createState() => _QrGeneratorViewState();
}

class _QrGeneratorViewState extends State<QrGeneratorView> {
  final _text = TextEditingController();
  final _extra = TextEditingController();
  final _email = TextEditingController();
  final _org = TextEditingController();
  final _preview = GlobalKey();
  QrKind _kind = QrKind.text;
  var _sms = false;
  String? _payload;

  @override
  void dispose() {
    _text.dispose();
    _extra.dispose();
    _email.dispose();
    _org.dispose();
    super.dispose();
  }

  Future<void> _onNlp(GeminiAnswer answer) async {
    final action = NlpAction.tryParse(answer.text);
    if (action == null) return;
    setState(() {
      _kind = qrKindFromName(action.kind);
      if (action.text.isNotEmpty) _text.text = action.text;
    });
  }

  Future<void> _make() async {
    final payload = buildQrPayload(
      _kind,
      {
        'text': _text.text,
        'extra': _extra.text,
        'email': _email.text,
        'org': _org.text,
        'phone': _text.text,
      },
      sms: _sms,
    );
    if (payload.trim().isEmpty) return;
    setState(() => _payload = payload);
    if (!mounted) return;
    await recordJob(
      context,
      tool: 'qr-generator',
      title: kQrKindLabels[_kind]!,
      detail: payload,
      extra: {'request': _text.text, 'result': payload, 'status': 'done'},
    );
  }

  Future<void> _download() async {
    final bytes = await capturePng(_preview);
    if (bytes == null || !mounted) return;
    await downloadFile(context, bytes: bytes, filename: 'qr.png', mimeType: 'image/png');
  }

  @override
  Widget build(BuildContext context) {
    return FeatureScaffold(
      title: 'QR 생성',
      subtitle: '종류를 고르고 내용을 적으면 바로 코드가 생겨요',
      emoji: '📱',
      accent: AppTheme.lavender,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NlpRequestBar(
            tool: 'qr-generator',
            hint: '예: 워크샵 주소를 URL QR로 만들어 줘',
            ask: askQrGenerator,
            onAnswer: _onNlp,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<QrKind>(
            initialValue: _kind,
            decoration: const InputDecoration(labelText: '종류'),
            items: [
              for (final entry in kQrKindLabels.entries)
                DropdownMenuItem(value: entry.key, child: Text(entry.value)),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _kind = value);
            },
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _text,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(hintText: '무엇이든 QR코드로 만들어 봐요!'),
          ),
          if (_kind == QrKind.email || _kind == QrKind.phone || _kind == QrKind.event) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _extra,
              decoration: InputDecoration(
                hintText: switch (_kind) {
                  QrKind.email => '제목',
                  QrKind.phone => 'SMS 내용',
                  QrKind.event => '날짜 2026-09-23',
                  _ => '',
                },
              ),
            ),
          ],
          if (_kind == QrKind.card) ...[
            const SizedBox(height: 8),
            TextField(controller: _email, decoration: const InputDecoration(hintText: '이메일')),
            const SizedBox(height: 8),
            TextField(controller: _org, decoration: const InputDecoration(hintText: '회사 또는 팀')),
            const SizedBox(height: 8),
            TextField(controller: _extra, decoration: const InputDecoration(hintText: '전화번호')),
          ],
          if (_kind == QrKind.phone)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('SMS로 만들기'),
              value: _sms,
              onChanged: (value) => setState(() => _sms = value),
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: GoButton(onPressed: _make),
          ),
          if (_payload != null) ...[
            const SizedBox(height: 12),
            SectionCard(
              child: Column(
                children: [
                  RepaintBoundary(
                    key: _preview,
                    child: ColoredBox(
                      color: Colors.white,
                      child: QrImageView(data: _payload!, size: 220, backgroundColor: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(_payload!, textAlign: TextAlign.center, style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: _download,
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('다운로드'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
