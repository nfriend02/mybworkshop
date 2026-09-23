class Slide {
  const Slide({required this.title, required this.body});

  final String title;
  final String body;
}

/// Turns markdown headings into presentation slides.
List<Slide> parseMarkdownSlides(String markdown) {
  final slides = <Slide>[];
  String? title;
  final body = <String>[];

  void flush() {
    if (title == null && body.isEmpty) return;
    slides.add(
      Slide(
        title: title ?? '슬라이드',
        body: body.join('\n').trim(),
      ),
    );
    body.clear();
  }

  for (final raw in markdown.split('\n')) {
    final line = raw.trimRight();
    final heading = RegExp(r'^#{1,3}\s+(.*)$').firstMatch(line.trim());
    if (heading != null) {
      flush();
      title = heading.group(1)!.trim();
      continue;
    }
    if (line.trim().isEmpty && body.isEmpty) continue;
    body.add(line);
  }
  flush();

  if (slides.isEmpty && markdown.trim().isNotEmpty) {
    return [Slide(title: '슬라이드', body: markdown.trim())];
  }
  return slides;
}
