import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mybworkshop/features/audio_tools/domain/wav_edit.dart';
import 'package:mybworkshop/features/audio_tools/domain/wav_tone.dart';
import 'package:mybworkshop/features/data_visualizer/domain/csv_series.dart';
import 'package:mybworkshop/features/document_compressor/domain/document_compress.dart';
import 'package:mybworkshop/features/document_compressor/domain/zip_compressor.dart';
import 'package:mybworkshop/features/gif_editor/domain/gif_clip.dart';
import 'package:mybworkshop/features/gif_generator/domain/fps_limit.dart';
import 'package:mybworkshop/features/gif_generator/domain/gif_builder.dart';
import 'package:mybworkshop/features/image_resizer/domain/aspect_fit.dart';
import 'package:mybworkshop/features/markdown_presentation/domain/slide_parser.dart';
import 'package:mybworkshop/features/qr_generator/domain/qr_payload.dart';
import 'package:mybworkshop/features/text_summarizer/domain/extractive_summarizer.dart';
import 'package:mybworkshop/shared/api/nlp_action.dart';

void main() {
  test('summarizer keeps the highest scoring sentences', () {
    const text =
        '고양이는 낮잠을 잔다. 강아지는 산책을 좋아하고 산책을 또 좋아한다. 새는 하늘을 난다.';
    final summary = ExtractiveSummarizer.summarize(text, maxSentences: 1);
    expect(summary, contains('산책'));
  });

  test('markdown headings become slides', () {
    const markdown = '# 하나\n본문\n\n## 둘\n- 항목';
    final slides = parseMarkdownSlides(markdown);
    expect(slides, hasLength(2));
    expect(slides.first.title, '하나');
    expect(slides.last.body, contains('항목'));
  });

  test('csv parser skips a text header', () {
    const raw = '이름,값\n월,3\n화,5';
    final points = parseCsvSeries(raw);
    expect(points.map((point) => point.label), ['월', '화']);
    expect(points.last.value, 5);
  });

  test('wav header is RIFF WAVE', () {
    final wav = buildSineWav(frequencyHz: 440, seconds: 0.1);
    expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
    expect(String.fromCharCodes(wav.sublist(8, 12)), 'WAVE');
  });

  test('zip archive starts with the PK signature', () {
    final zip = zipFiles({'note.txt': Uint8List.fromList([104, 105])});
    expect(zip[0], 0x50);
    expect(zip[1], 0x4b);
  });

  test('caption gif starts with the GIF signature', () {
    final gif = buildCaptionGif(
      text: 'Hi',
      red: 255,
      green: 220,
      blue: 230,
      frameCount: 2,
      delayMs: 100,
    );
    expect(String.fromCharCodes(gif.sublist(0, 3)), 'GIF');
  });

  test('gif resize keeps the GIF signature', () {
    final gif = buildCaptionGif(
      text: 'Hi',
      red: 255,
      green: 220,
      blue: 230,
      frameCount: 2,
      delayMs: 100,
    );
    final resized = GifClip.decode(gif, 'hi.gif').resized(40, 24).encode();
    expect(String.fromCharCodes(resized.sublist(0, 3)), 'GIF');
  });

  test('aspect crop makes a square', () {
    final src = img.Image(width: 100, height: 50);
    img.fill(src, color: img.ColorRgb8(255, 0, 0));
    final fitted = fitToBox(
      img.encodePng(src),
      width: 40,
      height: 40,
      mode: FitMode.crop,
    );
    final decoded = img.decodePng(fitted)!;
    expect(decoded.width, decoded.height);
  });

  test('gif fps never exceeds 29', () {
    expect(clampGifFps(40), 29);
    expect(delayMsForFps(29), (1000 / 29).round());
  });

  test('hwp uploads are blocked', () {
    expect(
      () => compressDocument(name: 'note.hwp', bytes: Uint8List(4)),
      throwsA(
        isA<HwpBlocked>().having(
          (error) => error.message,
          'message',
          'PDF/Word로 변환 후 업로드',
        ),
      ),
    );
  });

  test('qr payloads add a scheme and a mailto link', () {
    expect(buildQrPayload(QrKind.url, {'text': 'example.com'}), 'https://example.com');
    expect(buildQrPayload(QrKind.email, {'text': 'a@b.c', 'email': 'a@b.c'}), contains('mailto:a@b.c'));
  });

  test('nlp action reads a resize request', () {
    final action = NlpAction.tryParse('{"tool":"resize","width":10,"height":20,"note":"ok"}');
    expect(action!.tool, 'resize');
    expect(action.width, 10);
  });

  test('wav volume stays a RIFF file', () {
    final wav = WavPcm.tryParse(buildSineWav(frequencyHz: 440, seconds: 0.05));
    final quieter = wav!.atVolume(0.5).encode();
    expect(String.fromCharCodes(quieter.sublist(0, 4)), 'RIFF');
  });
}
