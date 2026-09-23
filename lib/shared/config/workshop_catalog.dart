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
    label: 'GIF 편집',
    emoji: '🎬',
    icon: Icons.movie_filter_rounded,
    path: '/gif-editor',
    color: Color(0xFFFFC2D4),
    blurb: '프레임을 이어 붙이고 속도를 조절해요',
  ),
  WorkshopTool(
    label: '이미지 리사이즈',
    emoji: '🖼️',
    icon: Icons.photo_size_select_large_rounded,
    path: '/image-resizer',
    color: Color(0xFFC8F2E0),
    blurb: '원하는 너비로 이미지를 줄여요',
  ),
  WorkshopTool(
    label: 'GIF 생성',
    emoji: '✨',
    icon: Icons.auto_awesome_rounded,
    path: '/gif-generator',
    color: Color(0xFFFFF1B8),
    blurb: '글자와 색으로 짧은 GIF를 만들어요',
  ),
  WorkshopTool(
    label: '문서 압축',
    emoji: '📦',
    icon: Icons.folder_zip_rounded,
    path: '/documents',
    color: Color(0xFFD4EFFF),
    blurb: '여러 파일을 ZIP으로 묶어요',
  ),
  WorkshopTool(
    label: 'QR 생성',
    emoji: '📱',
    icon: Icons.qr_code_2_rounded,
    path: '/qr',
    color: Color(0xFFE4D7FF),
    blurb: '문장을 바로 스캔되는 QR로',
  ),
  WorkshopTool(
    label: '오디오 도구',
    emoji: '🎵',
    icon: Icons.graphic_eq_rounded,
    path: '/audio',
    color: Color(0xFFFFD3C4),
    blurb: '톤을 만들고 템포를 재요',
  ),
  WorkshopTool(
    label: '텍스트 요약',
    emoji: '📝',
    icon: Icons.notes_rounded,
    path: '/summarize',
    color: Color(0xFFCDECCF),
    blurb: '긴 글을 핵심 문장으로 줄여요',
  ),
  WorkshopTool(
    label: '밈 생성',
    emoji: '😂',
    icon: Icons.sentiment_very_satisfied_rounded,
    path: '/meme',
    color: Color(0xFFFFE0F0),
    blurb: '위아래 자막이 있는 밈을 그려요',
  ),
  WorkshopTool(
    label: '데이터 시각화',
    emoji: '📊',
    icon: Icons.bar_chart_rounded,
    path: '/visualize',
    color: Color(0xFFD9F6FF),
    blurb: 'CSV를 파스텔 막대 차트로',
  ),
  WorkshopTool(
    label: 'AI 아바타',
    emoji: '🧑‍🎨',
    icon: Icons.face_retouching_natural_rounded,
    path: '/avatar',
    color: Color(0xFFF3D6FF),
    blurb: '이름에서 고유한 얼굴을 만들어요',
  ),
  WorkshopTool(
    label: '마크다운 발표',
    emoji: '📽️',
    icon: Icons.slideshow_rounded,
    path: '/slides',
    color: Color(0xFFFFF0C9),
    blurb: '마크다운 제목을 슬라이드로',
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
