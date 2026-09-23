import '../../../shared/api/gemini_client.dart';
import '../../../shared/api/local_action.dart';

Future<GeminiAnswer> askVisualizer(String request) async {
  final remote = await GeminiClient().ask(
    request: request,
    json: true,
    instruction:
        '데이터 시각화 도구입니다. chart는 bar, line, pie, heatmap 중 하나입니다. '
        'JSON만 반환하세요. 예: {"tool":"chart","chart":"pie","note":"비율은 파이가 잘 보여요"}',
  );
  return preferParsed(remote, localChart(request));
}
