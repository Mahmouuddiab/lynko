class UploadedMediaEntity {
  final String url;
  final String? fileName;
  final int? fileSizeBytes;

  const UploadedMediaEntity({required this.url, this.fileName, this.fileSizeBytes});
}