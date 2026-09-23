import '../../../shared/api/gemini_client.dart';
import '../../../shared/api/local_action.dart';

Future<GeminiAnswer> askImageResizer(String request) async {
  final remote = await GeminiClient().ask(
    request: request,
    json: true,
    instruction:
        '이미지 리사이저입니다. ratio는 가로:세로 비율입니다. 1:1, 3:4, 4:3, 9:16, 16:9 또는 사용자가 말한 비율(예: 3:6)을 그대로 적고, mode는 padding 또는 crop입니다. '
        'JSON만 반환하세요. 예: {"tool":"resize","ratio":"3:6","mode":"padding","note":"3:6 비율로 맞출게요"}',
  );
  return preferParsed(remote, localResize(request));
}
