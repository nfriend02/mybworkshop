import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Starts the queued upload. Sits on the right of the file actions.
class GoButton extends StatelessWidget {
  const GoButton({super.key, required this.onPressed, this.busy = false});

  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: busy ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF7DDBB0),
        foregroundColor: const Color(0xFF1F3D2E),
        disabledBackgroundColor: const Color(0xFFCDEBD9),
        disabledForegroundColor: const Color(0xFF5E7A6A),
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Text(
        busy ? '...' : 'GO',
        style: GoogleFonts.fredoka(fontSize: 22, fontWeight: FontWeight.w700),
      ),
    );
  }
}
