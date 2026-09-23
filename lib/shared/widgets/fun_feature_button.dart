import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme/app_theme.dart';

class FunFeatureButton extends StatefulWidget {
  const FunFeatureButton({
    super.key,
    required this.label,
    required this.emoji,
    required this.color,
    required this.blurb,
    required this.onTap,
    this.index = 0,
  });

  final String label;
  final String emoji;
  final Color color;
  final String blurb;
  final VoidCallback onTap;
  final int index;

  @override
  State<FunFeatureButton> createState() => _FunFeatureButtonState();
}

class _FunFeatureButtonState extends State<FunFeatureButton> {
  bool _hover = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scale = _pressed ? 0.96 : (_hover ? 1.03 : 1.0);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        child: AnimatedScale(
          scale: scale,
          duration: Duration(milliseconds: 120 + widget.index * 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: _hover ? 0.55 : 0.28),
                  blurRadius: _hover ? 16 : 0,
                  offset: Offset(0, _hover ? 8 : 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.emoji, style: const TextStyle(fontSize: 28)),
                const Spacer(),
                Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.notoSansKr(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: AppTheme.ink,
                  ),
                ),
                Text(
                  widget.blurb,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 11.5,
                    height: 1.25,
                    color: AppTheme.ink.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
