import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../../gif_editor/domain/gif_composer.dart';

/// Builds a short looping GIF from a caption and a pastel background.
Uint8List buildCaptionGif({
  required String text,
  required int red,
  required int green,
  required int blue,
  int frameCount = 8,
  int delayMs = 120,
}) {
  const width = 280;
  const height = 160;
  final label = text.trim().isEmpty ? 'My AI Workshop' : text.trim();
  final shown = label.length > 18 ? label.substring(0, 18) : label;
  final frames = <img.Image>[];

  for (var i = 0; i < frameCount.clamp(2, 12); i++) {
    final frame = img.Image(width: width, height: height);
    img.fill(frame, color: img.ColorRgb8(red, green, blue));
    final cx = 48 + ((i * 26) % (width - 90));
    final cy = 92 + (math.sin(i / 1.4) * 10).round();
    img.fillCircle(
      frame,
      x: cx,
      y: cy,
      radius: 22,
      color: img.ColorRgb8(255, 255, 255),
    );
    img.drawString(
      frame,
      shown,
      font: img.arial24,
      x: 12,
      y: 14,
      color: img.ColorRgb8(58, 49, 88),
    );
    frames.add(frame);
  }

  return encodeGifFrames(frames, delayMs: delayMs);
}
