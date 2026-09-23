import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

class WorkshopTool {
  const WorkshopTool({
    required this.label,
    required this.emoji,
    required this.icon,
    required this.path,
    required this.color,
    required this.blurb,
  });

  final String label;
  final String emoji;
  final IconData icon;
  final String path;
  final Color color;
  final String blurb;
}

const WorkshopTool kHomeTool = WorkshopTool(
  label: '홈',
  emoji: '🏠',
  icon: Icons.home_rounded,
  path: '/',
  color: AppTheme.butter,
  blurb: '워크샵 로비',
);

const WorkshopTool kUploadTool = WorkshopTool(
  label: '업로드',
  emoji: '☁️',
  icon: Icons.cloud_upload_rounded,
  path: '/upload',
  color: AppTheme.sky,
  blurb: '전시 체크리스트',
);

const List<WorkshopTool> kWorkshopTools = [
  WorkshopTool(
    label: 'GIF 편집기',
    emoji: '🎬',
    icon: Icons.movie_filter_rounded,
    path: '/gif-editor',
    color: Color(0xFFFFC2D4),
    blurb: '원본 GIF와 오른쪽 도구로 크기, 자르기, 속도를 편집해요',
  ),
  WorkshopTool(
    label: '이미지 리사이즈',
    emoji: '🖼️',
    icon: Icons.photo_size_select_large_rounded,
    path: '/image-resizer',
    color: Color(0xFFC8F2E0),
    blurb: '비율에 맞추고 ZIP은 한 장씩 풀어요',
  ),
  WorkshopTool(
    label: 'GIF 생성',
    emoji: '✨',
    icon: Icons.auto_awesome_rounded,
    path: '/gif-generator',
    color: Color(0xFFFFF1B8),
    blurb: '사진을 이어 최대 29FPS GIF로 만들어요',
  ),
  WorkshopTool(
    label: '문서 압축',
    emoji: '📦',
    icon: Icons.folder_zip_rounded,
    path: '/documents',
    color: Color(0xFFD4EFFF),
    blurb: '이미지를 낮추고 PDF는 저화질로 다시 묶어요',
  ),
  WorkshopTool(
    label: 'QR 생성',
    emoji: '📱',
    icon: Icons.qr_code_2_rounded,
    path: '/qr',
    color: Color(0xFFE4D7FF),
    blurb: '텍스트부터 명함, 일정까지 QR로',
  ),
  WorkshopTool(
    label: '오디오 도구',
    emoji: '🎵',
    icon: Icons.graphic_eq_rounded,
    path: '/audio',
    color: Color(0xFFFFD3C4),
    blurb: '파형을 보며 속도, 볼륨, 노이즈를 다뤄요',
  ),
  WorkshopTool(
    label: '요약/번역',
    emoji: '📝',
    icon: Icons.notes_rounded,
    path: '/summarize',
    color: Color(0xFFCDECCF),
    blurb: 'Gemini로 요약하고 다른 언어로 옮겨요',
  ),
  WorkshopTool(
    label: '밈 생성',
    emoji: '😂',
    icon: Icons.sentiment_very_satisfied_rounded,
    path: '/meme',
    color: Color(0xFFFFE0F0),
    blurb: '사진과 문구로 밈을 만들고 받아요',
  ),
  WorkshopTool(
    label: '데이터 시각화',
    emoji: '📊',
    icon: Icons.bar_chart_rounded,
    path: '/visualize',
    color: Color(0xFFD9F6FF),
    blurb: 'CSV와 Excel을 막대, 선, 파이, 히트맵으로',
  ),
  WorkshopTool(
    label: 'AI 아바타',
    emoji: '🧑‍🎨',
    icon: Icons.face_retouching_natural_rounded,
    path: '/avatar',
    color: Color(0xFFF3D6FF),
    blurb: '사진과 스타일로 아바타를 만들어요',
  ),
  WorkshopTool(
    label: '마크다운 발표',
    emoji: '📽️',
    icon: Icons.slideshow_rounded,
    path: '/slides',
    color: Color(0xFFFFF0C9),
    blurb: '마크다운을 테마 슬라이드로 넘겨요',
  ),
];

WorkshopTool toolForPath(String location) {
  if (location == kUploadTool.path ||
      location.startsWith('${kUploadTool.path}/')) {
    return kUploadTool;
  }
  for (final tool in kWorkshopTools) {
    if (location == tool.path || location.startsWith('${tool.path}/')) {
      return tool;
    }
  }
  return kHomeTool;
}
