import '../../../shared/api/gemini_client.dart';
import '../../../shared/api/local_action.dart';

Future<GeminiAnswer> askSlides(String request) async {
  final remote = await GeminiClient().ask(
    request: request,
    json: true,
    instruction:
        '마크다운 발표 변환기입니다. theme은 파스텔, 민트, 버터, 라벤더, 스카이 중 하나입니다. '
        'JSON만 반환하세요. 예: {"tool":"theme","theme":"민트","note":"민트 테마로 슬라이드를 볼까요"}',
  );
  return preferParsed(remote, localSlides(request));
}
