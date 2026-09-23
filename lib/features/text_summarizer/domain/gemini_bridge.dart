import '../../../shared/api/gemini_client.dart';

Future<GeminiAnswer> askSummarizer({
  required String request,
  required String language,
  required bool translate,
}) {
  final task = translate ? '$language 로 번역' : '$language 로 요약';
  return GeminiClient().ask(
    request: request,
    instruction:
        '텍스트 $task 도우미입니다. 설명 없이 결과 문장만 한국어 또는 요청한 언어로 출력하세요. '
        '요약이면 핵심 3문장 안쪽, 번역이면 원문 의미를 유지하세요.',
  );
}
