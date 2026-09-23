import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Encodes equally sized frames into an animated GIF.
Uint8List encodeGifFrames(List<img.Image> frames, {required int delayMs}) {
  if (frames.isEmpty) {
    throw StateError('프레임이 없어요');
  }
  final centi = (delayMs / 10).round().clamp(2, 500);
  final encoder = img.GifEncoder(
    delay: centi,
    repeat: 0,
    numColors: 64,
    quantizerType: img.QuantizerType.octree,
    dither: img.DitherKernel.none,
  );
  for (final frame in frames) {
    encoder.addFrame(frame, duration: centi);
  }
  final bytes = encoder.finish();
  if (bytes == null || bytes.isEmpty) {
    throw StateError('GIF 인코딩에 실패했어요');
  }
  return bytes;
}

/// Top-level entry so [compute] can run encoding off the UI isolate.
Uint8List composeGifEntry(Map<String, Object> args) {
  final frames = (args['frames'] as List).cast<Uint8List>();
  final delayMs = args['delayMs'] as int;
  final decoded = <img.Image>[];
  for (final bytes in frames) {
    final image = img.decodeImage(bytes);
    if (image != null) decoded.add(image);
  }
  if (decoded.isEmpty) {
    throw StateError('프레임을 읽지 못했어요');
  }

  const maxSide = 320;
  var width = decoded.first.width;
  var height = decoded.first.height;
  if (width > maxSide) {
    height = (height * maxSide / width).round();
    width = maxSide;
  }
  if (height > maxSide) {
    width = (width * maxSide / height).round();
    height = maxSide;
  }
  width = width.clamp(16, maxSide);
  height = height.clamp(16, maxSide);

  final fitted = [
    for (final image in decoded)
      img.copyResize(
        image,
        width: width,
        height: height,
        interpolation: img.Interpolation.average,
      ),
  ];
  return encodeGifFrames(fitted, delayMs: delayMs);
}

Future<Uint8List> composeGif(List<Uint8List> frames, int delayMs) async {
  final args = <String, Object>{'frames': frames, 'delayMs': delayMs};
  try {
    return await compute(composeGifEntry, args);
  } catch (_) {
    return composeGifEntry(args);
  }
}
