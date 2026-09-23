import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:web/web.dart';

import 'gif_clip.dart';
import 'gif_video_types.dart';

export 'gif_video_types.dart';

/// Records GIF frames through the browser. Prefers MP4 when the browser can record it.
Future<EncodedVideo> encodeGifVideo(GifClip clip) async {
  final mime = _recordMime();
  if (mime == null) {
    throw StateError('이 브라우저에서는 MP4 또는 WebM 녹화를 지원하지 않아요');
  }

  final width = clip.width.isEven ? clip.width : clip.width + 1;
  final height = clip.height.isEven ? clip.height : clip.height + 1;
  final canvas = HTMLCanvasElement()
    ..width = width
    ..height = height;
  final context = canvas.getContext('2d') as CanvasRenderingContext2D?;
  if (context == null) {
    throw StateError('영상 화면을 만들지 못했어요');
  }

  final fps = clip.fps.round().clamp(1, 30);
  final recorder = MediaRecorder(
    canvas.captureStream(fps),
    MediaRecorderOptions(mimeType: mime, videoBitsPerSecond: 2_500_000),
  );
  final parts = <Blob>[];
  final stopped = Completer<void>();
  recorder.addEventListener(
    'dataavailable',
    ((Event event) {
      final blob = (event as BlobEvent).data;
      if (blob.size > 0) parts.add(blob);
    }).toJS,
  );
  recorder.addEventListener(
    'stop',
    ((Event _) {
      if (!stopped.isCompleted) stopped.complete();
    }).toJS,
  );
  recorder.addEventListener(
    'error',
    ((Event _) {
      if (!stopped.isCompleted) stopped.completeError(StateError('영상 녹화에 실패했어요'));
    }).toJS,
  );

  recorder.start();
  for (final frame in clip.frames) {
    _paint(context, frame, width, height);
    await Future<void>.delayed(Duration(milliseconds: clip.delayMs.clamp(40, 500)));
  }
  await Future<void>.delayed(Duration(milliseconds: clip.delayMs.clamp(40, 500)));
  recorder.stop();
  await stopped.future.timeout(const Duration(seconds: 20));

  final bytes = BytesBuilder(copy: false);
  for (final part in parts) {
    final buffer = await part.arrayBuffer().toDart;
    bytes.add(buffer.toDart.asUint8List());
  }
  final video = bytes.toBytes();
  if (video.isEmpty) {
    throw StateError('영상 파일이 비어 있어요');
  }
  final mp4 = mime.contains('mp4');
  return EncodedVideo(
    bytes: video,
    mime: mp4 ? 'video/mp4' : 'video/webm',
    extension: mp4 ? 'mp4' : 'webm',
  );
}

String? _recordMime() {
  const candidates = ['video/mp4', 'video/mp4;codecs=avc1', 'video/webm;codecs=vp8', 'video/webm'];
  for (final candidate in candidates) {
    if (MediaRecorder.isTypeSupported(candidate)) return candidate;
  }
  return null;
}

void _paint(CanvasRenderingContext2D context, img.Image frame, int width, int height) {
  final fitted = frame.width == width && frame.height == height
      ? frame
      : img.copyResize(frame, width: width, height: height);
  final pixels = fitted.getBytes(order: img.ChannelOrder.rgba);
  final data = ImageData(pixels.toJS, width, height.toJS);
  context.putImageData(data, 0, 0);
}
