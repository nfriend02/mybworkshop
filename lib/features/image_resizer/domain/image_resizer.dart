import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Resizes an encoded image so its width matches [targetWidth].
Uint8List resizeToWidth(Uint8List bytes, int targetWidth) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw FormatException('이미지를 읽지 못했어요');
  }
  final width = targetWidth.clamp(16, 4096);
  final resized = img.copyResize(
    decoded,
    width: width,
    interpolation: img.Interpolation.average,
  );
  return img.encodePng(resized);
}
