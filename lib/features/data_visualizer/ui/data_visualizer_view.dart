import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_theme.dart';
import '../../../shared/api/gemini_client.dart';
import '../../../shared/api/nlp_action.dart';
import '../../../shared/utils/capture_png.dart';
import '../../../shared/utils/download_file.dart';
import '../../../shared/utils/pick_files.dart';
import '../../../shared/utils/record_job.dart';
import '../../../shared/widgets/feature_scaffold.dart';
import '../../../shared/widgets/nlp_request_bar.dart';
import '../../../shared/widgets/scroll_paged_list.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/upload_drop_zone.dart';
import '../domain/csv_series.dart';
import '../domain/gemini_bridge.dart';
import '../domain/spreadsheet.dart';
import 'chart_painter.dart';

class DataVisualizerView extends StatefulWidget {
  const DataVisualizerView({super.key});

  @override
  State<DataVisualizerView> createState() => _DataVisualizerViewState();
}

class _DataVisualizerViewState extends State<DataVisualizerView> {
  final _chartKey = GlobalKey();
  List<DataPoint> _points = const [];
  ChartKind _kind = ChartKind.bar;
  String? _error;

  Future<void> _onNlp(GeminiAnswer answer) async {
    final action = NlpAction.tryParse(answer.text);
    if (action == null || action.chart.isEmpty) return;
    setState(() => _kind = chartKindFromName(action.chart));
  }

  Future<void> _load(List<PickedBytes> files) async {
    final file = files.first;
    try {
      final points = parseSpreadsheet(file.name, file.bytes);
      setState(() {
        _points = points;
        _error = null;
      });
      if (!mounted) return;
      await recordJob(
        context,
        tool: 'data-visualizer',
        title: file.name,
        detail: '${points.length}행',
        extra: {'status': 'done'},
      );
    } catch (error) {
      setState(() => _error = '$error');
    }
  }

  Future<void> _download() async {
    final bytes = await capturePng(_chartKey);
    if (bytes == null || !mounted) return;
    await downloadFile(context, bytes: bytes, filename: '${_kind.name}_chart.png', mimeType: 'image/png');
  }

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.notoSansKr(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.ink);
    return FeatureScaffold(
      title: '데이터 시각화',
      subtitle: 'CSV나 Excel을 올리고 차트 모양을 골라요',
      emoji: '📊',
      accent: const Color(0xFFD9F6FF),
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NlpRequestBar(
            tool: 'data-visualizer',
            hint: '예: 이 비율은 파이 차트로 보여 줘',
            ask: askVisualizer,
            onAnswer: _onNlp,
          ),
          const SizedBox(height: 8),
          if (_points.isEmpty)
            UploadDropZone(
              title: 'CSV 또는 Excel을 놓아요',
              subtitle: 'A열은 이름, B열은 숫자예요',
              buttonLabel: 'Select File',
              onPicked: _load,
              accent: AppTheme.sky,
            )
          else ...[
            Wrap(
              spacing: 8,
              children: [
                for (final entry in kChartLabels.entries)
                  ChoiceChip(
                    label: Text(entry.value),
                    selected: _kind == entry.key,
                    onSelected: (_) => setState(() => _kind = entry.key),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            RepaintBoundary(
              key: _chartKey,
              child: SectionCard(
                color: Colors.white,
                child: SizedBox(
                  height: 240,
                  child: CustomPaint(
                    painter: ChartPainter(points: _points, kind: _kind, labelStyle: style),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: _download,
                icon: const Icon(Icons.download_rounded),
                label: const Text('다운로드'),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ScrollPagedList<DataPoint>(
                items: _points,
                itemBuilder: (context, point, index) => ListTile(
                  dense: true,
                  title: Text(point.label),
                  trailing: Text(point.value.toString()),
                ),
              ),
            ),
          ],
          if (_error != null) Text(_error!, style: GoogleFonts.notoSansKr(color: AppTheme.coral, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
