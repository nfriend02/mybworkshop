import 'dart:convert';

import 'gemini_client.dart';
import 'nlp_action.dart';

/// Keeps a tool's settings when Gemini is busy, so GO can still run the request.
GeminiAnswer preferParsed(GeminiAnswer remote, String? localJson) {
  if (!remote.usedFallback && NlpAction.tryParse(remote.text) != null) {
    return remote;
  }
  if (localJson == null) return remote;
  return GeminiAnswer(text: localJson, usedFallback: true);
}

String readableAnswer(String text) {
  final action = NlpAction.tryParse(text);
  if (action == null) return text;
  if (action.note.isNotEmpty) return action.note;
  return '요청을 반영해 두었어요. GO를 누르면 진행해요.';
}

String? localResize(String request) {
  final ratio = RegExp(r'(\d+(?:\.\d+)?)\s*[:：]\s*(\d+(?:\.\d+)?)').firstMatch(request);
  final crop = RegExp(r'잘라|크롭|crop', caseSensitive: false).hasMatch(request);
  final mentioned = ratio != null || crop || RegExp(r'여백|패딩|padding|비율|맞춰|수정').hasMatch(request);
  if (!mentioned) return null;
  final label = ratio == null ? '1:1' : '${ratio.group(1)}:${ratio.group(2)}';
  final mode = crop ? 'crop' : 'padding';
  return jsonEncode({
    'tool': 'resize',
    'ratio': label,
    'mode': mode,
    'note': '$label 비율로 맞춰 두었어요. GO를 누르면 변환해요.',
  });
}

String? localGifFps(String request) {
  final match = RegExp(r'(\d{1,2})\s*(?:fps|프레임)', caseSensitive: false).firstMatch(request);
  if (match == null) return null;
  return jsonEncode({
    'tool': 'fps',
    'fps': int.parse(match.group(1)!),
    'note': '${match.group(1)}FPS로 맞춰 두었어요. GO를 누르면 GIF를 만들어요.',
  });
}

String? localGifTool(String request) {
  final tool = _gifTool(request);
  if (tool == null) return null;
  final width = RegExp(r'가로\s*(\d+)').firstMatch(request);
  final height = RegExp(r'세로\s*(\d+)').firstMatch(request);
  return jsonEncode({
    'tool': tool,
    if (width != null) 'width': int.parse(width.group(1)!),
    if (height != null) 'height': int.parse(height.group(1)!),
    'note': '편집 설정을 맞춰 두었어요. GO를 누르면 적용해요.',
  });
}

String? localChart(String request) {
  final chart = _chart(request);
  if (chart == null) return null;
  return jsonEncode({
    'tool': 'chart',
    'chart': chart,
    'note': '차트 모양을 맞춰 두었어요. GO를 누르면 그려요.',
  });
}

String? localAudio(String request) {
  final tool = _audioTool(request);
  if (tool == null) return null;
  final gain = RegExp(r'볼륨|소리').hasMatch(request) && RegExp(r'절반|낮').hasMatch(request) ? 0.5 : null;
  final speed = RegExp(r'느리').hasMatch(request)
      ? 0.5
      : RegExp(r'빠르|두 배|2배').hasMatch(request)
          ? 2.0
          : null;
  return jsonEncode({
    'tool': tool,
    'gain': ?gain,
    'speed': ?speed,
    'note': '오디오 설정을 맞춰 두었어요. GO를 누르면 적용해요.',
  });
}

String? localSlides(String request) {
  const themes = ['파스텔', '민트', '버터', '라벤더', '스카이'];
  final theme = themes.where(request.contains).firstOrNull;
  if (theme == null) return null;
  return jsonEncode({
    'tool': 'theme',
    'theme': theme,
    'note': '$theme 테마로 맞춰 두었어요. GO를 누르면 슬라이드를 만들어요.',
  });
}

String? localAvatar(String request) {
  final style = _avatar(request);
  if (style == null) return null;
  return jsonEncode({
    'tool': 'avatar',
    'style': style,
    'note': '$style 스타일로 맞춰 두었어요. GO를 누르면 아바타를 만들어요.',
  });
}

String? _gifTool(String request) {
  if (RegExp(r'잘라|크롭|crop', caseSensitive: false).hasMatch(request)) return 'crop';
  if (RegExp(r'회전|돌려').hasMatch(request)) return 'rotate';
  if (RegExp(r'거꾸로|역재생').hasMatch(request)) return 'reverse';
  if (RegExp(r'빠르|느리|속도').hasMatch(request)) return 'speed';
  if (RegExp(r'최적화|용량').hasMatch(request)) return 'optimize';
  if (RegExp(r'구간|자르').hasMatch(request)) return 'cut';
  if (RegExp(r'변환').hasMatch(request)) return 'convert';
  if (RegExp(r'줄이|리사이즈|resize', caseSensitive: false).hasMatch(request)) return 'resize';
  return null;
}

String? _chart(String request) {
  if (request.contains('파이') || RegExp(r'pie', caseSensitive: false).hasMatch(request)) return 'pie';
  if (request.contains('히트') || RegExp(r'heat', caseSensitive: false).hasMatch(request)) return 'heatmap';
  if (RegExp(r'선\s*차트|꺾은선|라인\s*차트|line', caseSensitive: false).hasMatch(request)) return 'line';
  if (request.contains('막대') || RegExp(r'bar', caseSensitive: false).hasMatch(request)) return 'bar';
  return null;
}

String? _audioTool(String request) {
  if (RegExp(r'볼륨|소리').hasMatch(request)) return 'volume';
  if (RegExp(r'빠르|느리|속도').hasMatch(request)) return 'speed';
  if (RegExp(r'노이즈|잡음').hasMatch(request)) return 'denoise';
  if (RegExp(r'압축|가볍게').hasMatch(request)) return 'compress';
  if (request.contains('변환')) return 'convert';
  return null;
}

String? _avatar(String request) {
  if (request.contains('픽셀')) return '픽셀';
  if (request.contains('라인')) return '라인';
  if (request.contains('스티커')) return '스티커';
  if (request.contains('파스텔')) return '파스텔';
  return null;
}
