import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/ai_avatar/domain/avatar_spec.dart';
import '../../shared/utils/capture_png.dart';
import '../../shared/utils/record_job.dart';
import '../../shared/utils/save_bytes.dart';
import '../../shared/widgets/feature_scaffold.dart';

class AiAvatarPage extends StatefulWidget {
  const AiAvatarPage({super.key});

  @override
  State<AiAvatarPage> createState() => _AiAvatarPageState();
}

class _AiAvatarPageState extends State<AiAvatarPage> {
  final _name = TextEditingController(text: 'My Branch');
  final _boundary = GlobalKey();
  bool _spark = true;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final png = await capturePng(_boundary);
    if (png == null || !mounted) return;
    await saveBytes(bytes: png, filename: 'avatar.png', mimeType: 'image/png');
    if (!mounted) return;
    await recordJob(context, tool: 'avatar', title: _name.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final spec = AvatarSpec.fromName(_name.text, spark: _spark);
    return FeatureScaffold(
      title: 'AI 아바타',
      subtitle: '이름에서 색, 눈, 표정을 정해요',
      emoji: '🧑‍🎨',
      accent: const Color(0xFFF3D6FF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: '이름'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('반짝이'),
            value: _spark,
            onChanged: (value) => setState(() => _spark = value),
          ),
          Center(
            child: RepaintBoundary(
              key: _boundary,
              child: CustomPaint(
                painter: _AvatarPainter(spec),
                child: const SizedBox(width: 260, height: 260),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: _save, child: const Text('아바타 저장')),
        ],
      ),
    );
  }
}

class _AvatarPainter extends CustomPainter {
  _AvatarPainter(this.spec);
  final AvatarSpec spec;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = Radius.circular(size.width * 0.12);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, radius),
      Paint()..color = spec.background,
    );
    final center = Offset(size.width / 2, size.height * 0.42);
    canvas.drawCircle(
      center,
      size.width * 0.28,
      Paint()..color = Colors.white.withValues(alpha: 0.92),
    );
    final eye = Paint()..color = spec.ink;
    final spread = 16.0 + (spec.seed % 10);
    canvas.drawCircle(center.translate(-spread, -4), 5.5, eye);
    canvas.drawCircle(center.translate(spread, -4), 5.5, eye);
    final smile = Paint()
      ..color = spec.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(
        center: center.translate(0, 16),
        width: 54,
        height: 32,
      ),
      0.15,
      2.8,
      false,
      smile,
    );
    if (spec.spark) {
      final spark = Paint()..color = spec.accent;
      canvas.drawCircle(const Offset(36, 36), 8, spark);
      canvas.drawCircle(Offset(size.width - 42, 48), 5, spark);
    }
    final initials = TextPainter(
      text: TextSpan(
        text: spec.initials,
        style: GoogleFonts.fredoka(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: spec.ink,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    initials.paint(
      canvas,
      Offset((size.width - initials.width) / 2, size.height - 52),
    );
  }

  @override
  bool shouldRepaint(covariant _AvatarPainter oldDelegate) =>
      oldDelegate.spec != spec;
}
