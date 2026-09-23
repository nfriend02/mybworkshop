enum QrKind { text, url, email, card, phone, event, app }

const Map<QrKind, String> kQrKindLabels = {
  QrKind.text: '텍스트',
  QrKind.url: 'URL',
  QrKind.email: '이메일',
  QrKind.card: '명함',
  QrKind.phone: '전화/SMS',
  QrKind.event: '일정',
  QrKind.app: '앱 다운로드 링크',
};

QrKind qrKindFromName(String name) {
  final lower = name.trim().toLowerCase();
  for (final entry in kQrKindLabels.entries) {
    if (entry.value == name || entry.key.name == lower) return entry.key;
  }
  return switch (lower) {
    'url' || '링크' => QrKind.url,
    'email' || '이메일' => QrKind.email,
    'card' || '명함' || 'vcard' => QrKind.card,
    'phone' || 'sms' || '전화' => QrKind.phone,
    'event' || '일정' || 'calendar' => QrKind.event,
    'app' || '앱' => QrKind.app,
    _ => QrKind.text,
  };
}

String buildQrPayload(
  QrKind kind,
  Map<String, String> fields, {
  bool sms = false,
}) {
  final text = (fields['text'] ?? '').trim();
  final extra = (fields['extra'] ?? '').trim();
  final phone = (fields['phone'] ?? text).trim();
  final email = (fields['email'] ?? text).trim();
  return switch (kind) {
    QrKind.text => text,
    QrKind.url => _withScheme(text),
    QrKind.email => _mailto(email, extra),
    QrKind.card => _vcard(
      name: text,
      phone: phone == text ? extra : phone,
      email: (fields['email'] ?? '').trim(),
      org: (fields['org'] ?? '').trim(),
    ),
    QrKind.phone => sms ? 'SMSTO:$phone:${extra.isEmpty ? text : extra}' : 'tel:$phone',
    QrKind.event => _event(text, extra),
    QrKind.app => _withScheme(text),
  };
}

String _withScheme(String value) {
  if (value.isEmpty) return value;
  if (value.contains('://')) return value;
  return 'https://$value';
}

String _mailto(String email, String subject) {
  if (subject.isEmpty) return 'mailto:$email';
  return 'mailto:$email?subject=${Uri.encodeComponent(subject)}';
}

String _vcard({
  required String name,
  required String phone,
  required String email,
  required String org,
}) {
  return [
    'BEGIN:VCARD',
    'VERSION:3.0',
    'FN:$name',
    if (phone.isNotEmpty) 'TEL:$phone',
    if (email.isNotEmpty) 'EMAIL:$email',
    if (org.isNotEmpty) 'ORG:$org',
    'END:VCARD',
  ].join('\n');
}

String _event(String title, String day) {
  final compact = day.replaceAll(RegExp(r'[^0-9]'), '');
  final stamp = compact.length >= 8 ? compact.substring(0, 8) : '20260923';
  return [
    'BEGIN:VEVENT',
    'SUMMARY:$title',
    'DTSTART:$stamp',
    'END:VEVENT',
  ].join('\n');
}
