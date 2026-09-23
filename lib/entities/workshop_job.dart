class WorkshopJob {
  const WorkshopJob({
    required this.id,
    required this.tool,
    required this.title,
    required this.detail,
    required this.status,
    this.createdAtMs = 0,
  });

  final String id;
  final String tool;
  final String title;
  final String detail;
  final String status;
  final int createdAtMs;

  factory WorkshopJob.fromMap(Map<String, dynamic> data) {
    return WorkshopJob(
      id: data['id'] as String? ?? '',
      tool: data['tool'] as String? ?? 'workshop',
      title: data['title'] as String? ?? '(제목 없음)',
      detail: data['detail'] as String? ?? '',
      status: data['status'] as String? ?? 'active',
      createdAtMs: _ms(data['createdAt']),
    );
  }

  static int _ms(dynamic value) {
    if (value == null) return 0;
    try {
      return (value as dynamic).millisecondsSinceEpoch as int;
    } catch (_) {
      return 0;
    }
  }
}
