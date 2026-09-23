import '../../../shared/api/gemini_client.dart';

Future<GeminiAnswer> askImageResizer(String request) {
  return GeminiClient().ask(
    request: request,
    json: true,
    instruction:
        '이미지 리사이저입니다. ratio는 1:1, 3:4, 4:3, 9:16, 16:9, Custom 중 하나이고 mode는 padding 또는 crop입니다. '
        'JSON만 반환하세요. 예: {"tool":"resize","ratio":"1:1","mode":"crop","note":"정사각형으로 잘라 채웠어요"}',
  );
}
