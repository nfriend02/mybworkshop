class DataPoint {
  const DataPoint({required this.label, required this.value});

  final String label;
  final double value;
}

/// Parses `label,value` rows. A non-numeric first row is treated as a header.
List<DataPoint> parseCsvSeries(String raw) {
  final points = <DataPoint>[];
  var skippedHeader = false;
  for (final line in raw.split(RegExp(r'\r?\n'))) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    final parts = trimmed.split(RegExp(r'[,\t]'));
    if (parts.length < 2) continue;
    final label = parts.first.trim();
    final value = double.tryParse(parts[1].trim().replaceAll(',', ''));
    if (value == null) {
      if (!skippedHeader && points.isEmpty) {
        skippedHeader = true;
        continue;
      }
      continue;
    }
    if (label.isEmpty) continue;
    points.add(DataPoint(label: label, value: value));
  }
  return points;
}
