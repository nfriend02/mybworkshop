class UploadRecord {
  const UploadRecord({
    required this.id,
    required this.fileName,
    required this.size,
    required this.status,
  });

  final String id;
  final String fileName;
  final int size;
  final String status;

  Map<String, dynamic> toMap() {
    return {
      'fileName': fileName,
      'size': size,
      'status': status,
    };
  }
}
