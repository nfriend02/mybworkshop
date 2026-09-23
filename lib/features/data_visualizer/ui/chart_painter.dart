import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../domain/csv_series.dart';

enum ChartKind { bar, line, pie, heatmap }

const Map<ChartKind, String> kChartLabels = {
  ChartKind.bar: '막대',
  ChartKind.line: '선',
  ChartKind.pie: '파이',
  ChartKind.heatmap: '히트맵',
};

ChartKind chartKindFromName(String name) {
  final lower = name.trim().toLowerCase();
  return switch (lower) {
    'line' || '선' => ChartKind.line,
    'pie' || '파이' => ChartKind.pie,
    'heatmap' || '히트맵' => ChartKind.heatmap,
    _ => ChartKind.bar,
  };
}

class ChartPainter extends CustomPainter {
  ChartPainter({required this.points, required this.kind, required this.labelStyle});

  final List<DataPoint> points;
  final ChartKind kind;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    switch (kind) {
      case ChartKind.bar:
        _bars(canvas, size);
      case ChartKind.line:
        _line(canvas, size);
      case ChartKind.pie:
        _pie(canvas, size);
      case ChartKind.heatmap:
        _heat(canvas, size);
    }
  }

  void _bars(Canvas canvas, Size size) {
    final maxValue = points.map((point) => point.value.abs()).reduce(math.max);
    final gap = size.width / points.length;
    for (var i = 0; i < points.length; i++) {
      final height = maxValue == 0 ? 0.0 : (points[i].value.abs() / maxValue) * (size.height - 28);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(i * gap + 6, size.height - 24 - height, gap - 12, height),
        const Radius.circular(8),
      );
      canvas.drawRRect(rect, Paint()..color = _swatch(i));
      _label(canvas, points[i].label, Offset(i * gap + gap / 2, size.height - 4));
    }
  }

  void _line(Canvas canvas, Size size) {
    final maxValue = points.map((point) => point.value).reduce(math.max);
    final minValue = points.map((point) => point.value).reduce(math.min);
    final span = (maxValue - minValue).abs() < 0.001 ? 1.0 : maxValue - minValue;
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = points.length == 1 ? size.width / 2 : i * (size.width - 24) / (points.length - 1) + 12;
      final y = 16 + (1 - (points[i].value - minValue) / span) * (size.height - 44);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 5, Paint()..color = AppTheme.coral);
      _label(canvas, points[i].label, Offset(x, size.height - 4));
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = AppTheme.lilac
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  void _pie(Canvas canvas, Size size) {
    final values = [for (final point in points) point.value.abs()];
    final total = values.fold<double>(0, (sum, value) => sum + value);
    if (total == 0) return;
    final rect = Rect.fromCircle(center: Offset(size.width / 2, size.height / 2 - 8), radius: math.min(size.width, size.height) * 0.32);
    var start = -math.pi / 2;
    for (var i = 0; i < points.length; i++) {
      final sweep = values[i] / total * math.pi * 2;
      canvas.drawArc(rect, start, sweep, true, Paint()..color = _swatch(i));
      start += sweep;
    }
  }

  void _heat(Canvas canvas, Size size) {
    final columns = math.max(1, math.sqrt(points.length).ceil());
    final rows = (points.length / columns).ceil();
    final maxValue = points.map((point) => point.value.abs()).reduce(math.max);
    final cellW = size.width / columns;
    final cellH = (size.height - 8) / rows;
    for (var i = 0; i < points.length; i++) {
      final amount = maxValue == 0 ? 0.0 : points[i].value.abs() / maxValue;
      final color = Color.lerp(const Color(0xFFE7FFF4), AppTheme.coral, amount)!;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH((i % columns) * cellW + 4, (i ~/ columns) * cellH + 4, cellW - 8, cellH - 8),
        const Radius.circular(10),
      );
      canvas.drawRRect(rect, Paint()..color = color);
      _label(canvas, points[i].label, Offset((i % columns) * cellW + cellW / 2, (i ~/ columns) * cellH + cellH / 2));
    }
  }

  void _label(Canvas canvas, String text, Offset offset) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: labelStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: 72);
    painter.paint(canvas, offset - Offset(painter.width / 2, painter.height));
  }

  Color _swatch(int index) {
    const colors = [AppTheme.coral, AppTheme.lilac, Color(0xFF7DDBB0), Color(0xFFFFC46B), AppTheme.sky, AppTheme.peach];
    return colors[index % colors.length];
  }

  @override
  bool shouldRepaint(covariant ChartPainter oldDelegate) {
    return oldDelegate.kind != kind || oldDelegate.points != points;
  }
}
