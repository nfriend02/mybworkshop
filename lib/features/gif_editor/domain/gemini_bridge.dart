import '../../../shared/api/gemini_client.dart';
import '../../../shared/api/local_action.dart';

Future<GeminiAnswer> askGifEditor(String request) async {
  final remote = await GeminiClient().ask(
    request: request,
    json: true,
    instruction:
        'GIF 편집기입니다. 도구는 resize, crop, downsizing, convert, rotate, optimize, reverse, speed, cut 중 하나입니다. '
        'JSON만 반환하세요. 예: {"tool":"resize","width":240,"height":180,"delayMs":80,"note":"가로 240으로 줄였어요"}',
  );
  return preferParsed(remote, localGifTool(request));
}
