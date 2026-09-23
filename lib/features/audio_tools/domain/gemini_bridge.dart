import '../../../shared/api/gemini_client.dart';

Future<GeminiAnswer> askAudioTools(String request) {
  return GeminiClient().ask(
    request: request,
    json: true,
    instruction:
        '오디오 툴킷입니다. tool은 compress, convert, speed, volume, denoise 중 하나입니다. '
        'speed는 0.5~2, gain은 0~2입니다. JSON만 반환하세요. '
        '예: {"tool":"volume","gain":0.6,"speed":1,"note":"볼륨을 낮출게요"}',
  );
}
