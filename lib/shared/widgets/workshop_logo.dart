import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme/app_theme.dart';

/// Large wordmark for the home canvas, compact wordmark for the chrome.
class WorkshopLogo extends StatefulWidget {
  const WorkshopLogo({super.key, required this.compact});

  final bool compact;

  @override
  State<WorkshopLogo> createState() => _WorkshopLogoState();
}

class _WorkshopLogoState extends State<WorkshopLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    if (!widget.compact) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.compact ? 28.0 : 68.0;
    final logo = Column(
      crossAxisAlignment: widget.compact
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        ShaderMask(
          shaderCallback: (rect) => const LinearGradient(
            colors: [
              Color(0xFFFF6B9D),
              Color(0xFF8B6CFF),
              Color(0xFF3DDCFF),
            ],
          ).createShader(rect),
          child: Text(
            'My AI Workshop',
            textAlign: widget.compact ? TextAlign.left : TextAlign.center,
            style: GoogleFonts.fredoka(
              fontSize: size,
              fontWeight: FontWeight.w700,
              height: 0.95,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '나의 AI 워크샵',
          style: GoogleFonts.notoSansKr(
            fontSize: widget.compact ? 13 : 22,
            fontWeight: FontWeight.w800,
            color: AppTheme.ink.withValues(alpha: 0.78),
          ),
        ),
      ],
    );

    if (widget.compact) {
      return Semantics(label: 'My AI Workshop, 나의 AI 워크샵', child: logo);
    }

    return Semantics(
      label: 'My AI Workshop, 나의 AI 워크샵',
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.98, end: 1.04).animate(
          CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
        ),
        child: logo,
      ),
    );
  }
}
