String byteLabel(int length) {
  if (length < 1024) return '$length B';
  if (length < 1024 * 1024) return '${(length / 1024).toStringAsFixed(1)} KB';
  return '${(length / (1024 * 1024)).toStringAsFixed(1)} MB';
}

String fileStem(String name) {
  final slash = name.replaceAll('\\', '/');
  final base = slash.split('/').last;
  final dot = base.lastIndexOf('.');
  if (dot <= 0) return base;
  return base.substring(0, dot);
}

String mimeForName(String name) {
  final lower = name.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
  if (lower.endsWith('.gif')) return 'image/gif';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.wav')) return 'audio/wav';
  if (lower.endsWith('.pdf')) return 'application/pdf';
  if (lower.endsWith('.zip')) return 'application/zip';
  return 'application/octet-stream';
}
