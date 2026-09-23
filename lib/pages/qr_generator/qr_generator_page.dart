import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../app/theme/app_theme.dart';
import '../../shared/utils/capture_png.dart';
import '../../shared/utils/record_job.dart';
import '../../shared/utils/save_bytes.dart';
import '../../shared/widgets/feature_scaffold.dart';

class QrGeneratorPage extends StatefulWidget {
  const QrGeneratorPage({super.key});

  @override
  State<QrGeneratorPage> createState() => _QrGeneratorPageState();
}

class _QrGeneratorPageState extends State<QrGeneratorPage> {
  final _text = TextEditingController(text: 'https://mybworkshop.netlify.app');
  final _boundary = GlobalKey();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final png = await capturePng(_boundary);
    if (png == null || !mounted) return;
    await saveBytes(bytes: png, filename: 'qr.png', mimeType: 'image/png');
    if (!mounted) return;
    await recordJob(context, tool: 'qr', title: _text.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return FeatureScaffold(
      title: 'QR 생성',
      subtitle: '문장이나 링크를 바로 스캔되는 코드로',
      emoji: '📱',
      accent: const Color(0xFFE4D7FF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _text,
            decoration: const InputDecoration(labelText: '내용'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          Center(
            child: RepaintBoundary(
              key: _boundary,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: QrImageView(
                  data: _text.text.trim().isEmpty ? ' ' : _text.text.trim(),
                  size: 220,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: AppTheme.ink,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: AppTheme.ink,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _save,
            child: Text('PNG로 저장', style: GoogleFonts.notoSansKr()),
          ),
        ],
      ),
    );
  }
}
