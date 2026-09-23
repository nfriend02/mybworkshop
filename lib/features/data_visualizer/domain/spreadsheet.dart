import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import 'csv_series.dart';

List<DataPoint> parseSpreadsheet(String name, Uint8List bytes) {
  final lower = name.toLowerCase();
  if (lower.endsWith('.xlsx')) return _parseXlsx(bytes);
  return parseCsvSeries(utf8.decode(bytes, allowMalformed: true));
}

List<DataPoint> _parseXlsx(Uint8List bytes) {
  final archive = ZipDecoder().decodeBytes(bytes);
  ArchiveFile? sheet;
  ArchiveFile? shared;
  for (final file in archive.files) {
    final path = file.name.replaceAll('\\', '/');
    if (path.endsWith('xl/sharedStrings.xml')) shared = file;
    if (path.startsWith('xl/worksheets/sheet') && path.endsWith('.xml')) {
      sheet ??= file;
      if (path.endsWith('sheet1.xml')) sheet = file;
    }
  }
  if (sheet == null) {
    throw FormatException('Excel 시트를 찾지 못했어요. CSV로 저장해 올려 주세요.');
  }

  final strings = shared == null ? const <String>[] : _sharedStrings(utf8.decode(shared.content, allowMalformed: true));
  final xml = utf8.decode(sheet.content, allowMalformed: true);
  final points = <DataPoint>[];
  final rows = RegExp(r'<row\b[^>]*>([\s\S]*?)</row>').allMatches(xml);
  for (final row in rows) {
    final cells = RegExp(r'<c\b([^>]*)>(?:[\s\S]*?<v>([^<]*)</v>)?').allMatches(row.group(1)!);
    String? label;
    double? value;
    for (final cell in cells) {
      final attrs = cell.group(1) ?? '';
      final ref = RegExp(r'\br="([A-Z]+)').firstMatch(attrs)?.group(1);
      final raw = cell.group(2);
      if (ref == null || raw == null) continue;
      final sharedCell = attrs.contains('t="s"');
      final text = sharedCell ? (int.tryParse(raw) != null && int.parse(raw) < strings.length ? strings[int.parse(raw)] : raw) : raw;
      if (ref == 'A') label = text.trim();
      if (ref == 'B') value = double.tryParse(text.trim().replaceAll(',', ''));
    }
    if (label == null || label.isEmpty || value == null) continue;
    points.add(DataPoint(label: label, value: value));
  }
  if (points.isEmpty) {
    throw FormatException('A열 이름과 B열 숫자를 찾지 못했어요.');
  }
  return points;
}

List<String> _sharedStrings(String xml) {
  return [
    for (final item in RegExp(r'<si\b[^>]*>([\s\S]*?)</si>').allMatches(xml))
      RegExp(r'<t[^>]*>([\s\S]*?)</t>')
          .allMatches(item.group(1)!)
          .map((match) => match.group(1)!.replaceAll('&amp;', '&').replaceAll('&lt;', '<'))
          .join(),
  ];
}
