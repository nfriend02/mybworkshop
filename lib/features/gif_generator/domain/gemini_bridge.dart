import '../../../shared/api/gemini_client.dart';
import '../../../shared/api/local_action.dart';

Future<GeminiAnswer> askGifGenerator(String request) async {
  final remote = await GeminiClient().ask(
    request: request,
    json: true,
    instruction:
        'GIF 생성기입니다. FPS는 1부터 29까지입니다. JSON만 반환하세요. '
        '예: {"tool":"fps","fps":12,"note":"12FPS로 맞춰 둘게요"}',
  );
  return preferParsed(remote, localGifFps(request));
}
