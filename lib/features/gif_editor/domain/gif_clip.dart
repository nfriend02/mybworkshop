import 'dart:math' as math;
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

  double get fps => delayMs <= 0 ? 10 : 1000 / delayMs;

  factory GifClip.decode(Uint8List bytes, String name) {
    final image = img.decodeImage(bytes);
    if (image == null) {
      throw FormatException('이미지를 읽지 못했어요');
    }
    final frames = image.frames.length > 1
        ? [for (final frame in image.frames) img.Image.from(frame)]
        : [img.Image.from(image)];
    final duration = image.frameDuration > 0 ? image.frameDuration : 100;
    return GifClip(frames: frames, delayMs: duration.clamp(20, 2000).toInt(), name: name);
  }

  Uint8List encode() => encodeGifFrames(frames, delayMs: delayMs);

  Uint8List toPng() => img.encodePng(frames.first);

  Uint8List toJpg() => img.encodeJpg(frames.first, quality: 70);

  /// One frame of the current edit, small enough to redraw while a slider moves.
  Uint8List previewPng(
    img.Image Function(img.Image frame) transform, {
    int frameIndex = 0,
    int maxSide = 480,
  }) {
    final index = frameIndex.clamp(0, frames.length - 1);
    var frame = transform(img.Image.from(frames[index]));
    final longest = frame.width > frame.height ? frame.width : frame.height;
    if (longest > maxSide && longest > 0) {
      final scale = maxSide / longest;
      frame = img.copyResize(
        frame,
        width: (frame.width * scale).round().clamp(1, maxSide).toInt(),
        height: (frame.height * scale).round().clamp(1, maxSide).toInt(),
      );
    }
    return img.encodePng(frame);
  }

  GifClip resized(int width, int height) {
      final w = width.clamp(1, 8192).toInt();
      final h = height.clamp(1, 8192).toInt();
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
      final w = (frame.width - dx * 2).clamp(8, frame.width).toInt();
      final h = (frame.height - dy * 2).clamp(8, frame.height).toInt();
      return img.copyCrop(frame, x: dx, y: dy, width: w, height: h);
    });
  }

  GifClip cropAspect(
    double widthOverHeight, {
    required bool cover,
    img.ColorRgb8? pad,
  }) {
    final ratio = widthOverHeight <= 0 ? 1.0 : widthOverHeight;
    final color = pad ?? img.ColorRgb8(255, 255, 255);
    return _map((frame) => cropFrame(frame, widthOverHeight: ratio, cover: cover, pad: color));
  }

  GifClip downsized({
    required bool shrinkSize,
    required bool dropFrames,
    required bool lowerResolution,
  }) {
    var source = frames;
    var delay = delayMs;
    if (dropFrames && source.length > 1) {
      source = [for (var i = 0; i < source.length; i += 2) source[i]];
      delay = (delay * 2).clamp(20, 2000).toInt();
    }
    final clip = GifClip(
      frames: [for (final frame in source) img.Image.from(frame)],
      delayMs: delay,
      name: name,
    );
    return clip._map((frame) {
      var image = frame;
      if (shrinkSize) {
        image = img.copyResize(
          image,
          width: (image.width * 0.7).round().clamp(1, image.width).toInt(),
          height: (image.height * 0.7).round().clamp(1, image.height).toInt(),
        );
      }
      if (lowerResolution) {
        final longest = math.max(image.width, image.height);
        if (longest > 480) {
          final scale = 480 / longest;
          image = img.copyResize(
            image,
            width: (image.width * scale).round().clamp(1, 480).toInt(),
            height: (image.height * scale).round().clamp(1, 480).toInt(),
          );
        }
        image = img.quantize(
          image,
          numberOfColors: 32,
          method: img.QuantizeMethod.octree,
          dither: img.DitherKernel.none,
        );
      }
      return image;
    });
  }

  GifClip flipped({required bool horizontal, required bool vertical}) {
    return _map((frame) => flipFrame(frame, horizontal: horizontal, vertical: vertical));
  }

  GifClip scaled(double factor) {
    final scale = factor.clamp(0.15, 1);
    return _map((frame) {
      final w = (frame.width * scale).round().clamp(8, frame.width).toInt();
      final h = (frame.height * scale).round().clamp(8, frame.height).toInt();
      return img.copyResize(frame, width: w, height: h);
    });
  }

  GifClip rotated(int degrees) {
    final angle = degrees % 360;
    return _map((frame) => img.copyRotate(frame, angle: angle));
  }

  GifClip optimized() {
    return _map(
      (frame) => img.quantize(
        frame,
        numberOfColors: 128,
        method: img.QuantizeMethod.octree,
        dither: img.DitherKernel.none,
      ),
    );
  }

  GifClip reversed() {
    return GifClip(
      frames: [for (final frame in frames.reversed) img.Image.from(frame)],
      delayMs: delayMs,
      name: name,
    );
  }

  GifClip withDelay(int delay) {
    return GifClip(frames: frames, delayMs: delay.clamp(20, 1000).toInt(), name: name);
  }

  GifClip cut(int start, int end) {
    final from = start.clamp(0, frames.length - 1).toInt();
    final to = end.clamp(from, frames.length - 1).toInt();
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

img.Image cropFrame(
  img.Image frame, {
  required double widthOverHeight,
  required bool cover,
  img.ColorRgb8? pad,
}) {
  final ratio = widthOverHeight <= 0 ? 1.0 : widthOverHeight;
  final color = pad ?? img.ColorRgb8(255, 255, 255);
  final tw = frame.width.clamp(1, 8192);
  final th = (tw / ratio).round().clamp(1, 8192);
  if (cover) {
    final scale = math.max(tw / frame.width, th / frame.height);
    final rw = math.max(tw, (frame.width * scale).round());
    final rh = math.max(th, (frame.height * scale).round());
    final resized = img.copyResize(frame, width: rw, height: rh);
    final x = ((rw - tw) / 2).round().clamp(0, rw - tw);
    final y = ((rh - th) / 2).round().clamp(0, rh - th);
    return img.copyCrop(resized, x: x, y: y, width: tw, height: th);
  }
  final scale = math.min(tw / frame.width, th / frame.height);
  final rw = math.max(1, (frame.width * scale).round());
  final rh = math.max(1, (frame.height * scale).round());
  final resized = img.copyResize(frame, width: rw, height: rh);
  final canvas = img.Image(width: tw, height: th);
  img.fill(canvas, color: color);
  img.compositeImage(canvas, resized, dstX: ((tw - rw) / 2).round(), dstY: ((th - rh) / 2).round());
  return canvas;
}

img.Image flipFrame(img.Image frame, {required bool horizontal, required bool vertical}) {
  if (horizontal && vertical) return img.flipHorizontalVertical(frame);
  if (horizontal) return img.flipHorizontal(frame);
  if (vertical) return img.flipVertical(frame);
  return frame;
}
