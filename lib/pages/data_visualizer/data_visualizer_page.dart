import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme/app_theme.dart';
import '../../features/data_visualizer/domain/csv_series.dart';
import '../../shared/utils/record_job.dart';
import '../../shared/widgets/feature_scaffold.dart';

const _sample = '''
월,12
화,18
수,9
목,22
금,30
토,16
일,11
''';

class DataVisualizerPage extends StatefulWidget {
  const DataVisualizerPage({super.key});

  @override
  State<DataVisualizerPage> createState() => _DataVisualizerPageState();
}

class _DataVisualizerPageState extends State<DataVisualizerPage> {
  final _csv = TextEditingController(text: _sample);
  List<DataPoint> _points = parseCsvSeries(_sample);

  @override
  void dispose() {
    _csv.dispose();
    super.dispose();
  }

  void _parse() {
    setState(() => _points = parseCsvSeries(_csv.text));
  }

  @override
  Widget build(BuildContext context) {
    final values = _points.map((point) => point.value);
    final max = values.fold<double>(0, (a, b) => a > b ? a : b);
    final avg = _points.isEmpty
        ? 0
        : values.fold<double>(0, (a, b) => a + b) / _points.length;

    return FeatureScaffold(
      title: '데이터 시각화',
      subtitle: 'label,value 형식의 CSV를 막대로 그려요',
      emoji: '📊',
      accent: const Color(0xFFD9F6FF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _csv,
            minLines: 6,
            maxLines: 8,
            decoration: const InputDecoration(labelText: 'CSV'),
          ),
          const SizedBox(height: 8),
          FilledButton(onPressed: _parse, child: const Text('차트 그리기')),
          const SizedBox(height: 8),
          Text(
            _points.isEmpty
                ? '숫자 열이 없어요'
                : '${_points.length}개 · 최대 ${max.toStringAsFixed(1)} · 평균 ${avg.toStringAsFixed(1)}',
            style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: DecoratedBox(
              decoration: AppTheme.card(tint: AppTheme.sky),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: CustomPaint(
                  painter: _BarPainter(_points),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _points.isEmpty
                ? null
                : () => recordJob(
                      context,
                      tool: 'visualize',
                      title: '${_points.length}개 막대',
                      detail: 'avg ${avg.toStringAsFixed(1)}',
                    ),
            child: const Text('차트 기록'),
          ),
        ],
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter(this.points);
  final List<DataPoint> points;

  static const _colors = [
    Color(0xFFFF8BA7),
    Color(0xFF8ED9B5),
    Color(0xFFFFD56A),
    Color(0xFF8EC9F5),
    Color(0xFFC4B0FF),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final max = points.map((p) => p.value).reduce((a, b) => a > b ? a : b);
    final safeMax = max <= 0 ? 1.0 : max;
    final gap = 8.0;
    final barWidth = (size.width - gap * (points.length - 1)) / points.length;
    for (var i = 0; i < points.length; i++) {
      final height = (points[i].value / safeMax) * (size.height - 22);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(i * (barWidth + gap), size.height - 18 - height, barWidth, height),
        const Radius.circular(8),
      );
      canvas.drawRRect(rect, Paint()..color = _colors[i % _colors.length]);
      final label = TextPainter(
        text: TextSpan(
          text: points[i].label,
          style: const TextStyle(fontSize: 11, color: AppTheme.ink),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: barWidth);
      label.paint(canvas, Offset(i * (barWidth + gap), size.height - 14));
    }
  }

  @override
  bool shouldRepaint(covariant _BarPainter oldDelegate) =>
      oldDelegate.points != points;
}
