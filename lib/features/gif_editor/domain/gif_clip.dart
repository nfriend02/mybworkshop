import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'gif_composer.dart';

class GifClip {
  const GifClip({
    required this.frames,
    required this.delayMs,
    required this.name,
  });

  final List<img.Image> frames;
  final int delayMs;
  final String name;

  int get width => frames.first.width;
  int get height => frames.first.height;
  int get frameCount => frames.length;

  factory GifClip.decode(Uint8List bytes, String name) {
    final image = img.decodeImage(bytes);
    if (image == null) {
      throw FormatException('이미지를 읽지 못했어요');
    }
    final frames = image.frames.length > 1
        ? [for (final frame in image.frames) img.Image.from(frame)]
        : [img.Image.from(image)];
    final duration = image.frameDuration > 0 ? image.frameDuration : 100;
    return GifClip(frames: frames, delayMs: duration.clamp(20, 2000), name: name);
  }

  Uint8List encode() => encodeGifFrames(frames, delayMs: delayMs);

  Uint8List toPng() => img.encodePng(frames.first);

  Uint8List toJpg() => img.encodeJpg(frames.first, quality: 70);

  GifClip resized(int width, int height) {
    final w = width.clamp(8, 2048);
    final h = height.clamp(8, 2048);
    return _map(
      (frame) => img.copyResize(
        frame,
        width: w,
        height: h,
        interpolation: img.Interpolation.average,
      ),
    );
  }

  GifClip cropped(double inset) {
    final cut = inset.clamp(0, 0.4);
    return _map((frame) {
      final dx = (frame.width * cut).round();
      final dy = (frame.height * cut).round();
      final w = (frame.width - dx * 2).clamp(8, frame.width);
      final h = (frame.height - dy * 2).clamp(8, frame.height);
      return img.copyCrop(frame, x: dx, y: dy, width: w, height: h);
    });
  }

  GifClip scaled(double factor) {
    final scale = factor.clamp(0.15, 1);
    return _map((frame) {
      final w = (frame.width * scale).round().clamp(8, frame.width);
      final h = (frame.height * scale).round().clamp(8, frame.height);
      return img.copyResize(frame, width: w, height: h);
    });
  }

  GifClip rotated(int degrees) {
    final angle = degrees % 360;
    return _map((frame) => img.copyRotate(frame, angle: angle));
  }

  GifClip optimized() {
    return _map((frame) {
      final smaller = img.copyResize(
        frame,
        width: (frame.width * 0.75).round().clamp(8, frame.width),
        height: (frame.height * 0.75).round().clamp(8, frame.height),
      );
      return img.quantize(
        smaller,
        numberOfColors: 24,
        method: img.QuantizeMethod.octree,
        dither: img.DitherKernel.none,
      );
    });
  }

  GifClip reversed() {
    return GifClip(
      frames: [for (final frame in frames.reversed) img.Image.from(frame)],
      delayMs: delayMs,
      name: name,
    );
  }

  GifClip withDelay(int delay) {
    return GifClip(frames: frames, delayMs: delay.clamp(20, 1000), name: name);
  }

  GifClip cut(int start, int end) {
    final from = start.clamp(0, frames.length - 1);
    final to = end.clamp(from, frames.length - 1);
    return GifClip(
      frames: [for (final frame in frames.sublist(from, to + 1)) img.Image.from(frame)],
      delayMs: delayMs,
      name: name,
    );
  }

  GifClip _map(img.Image Function(img.Image frame) transform) {
    return GifClip(
      frames: [for (final frame in frames) transform(frame)],
      delayMs: delayMs,
      name: name,
    );
  }
}
