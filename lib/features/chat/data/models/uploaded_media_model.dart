import 'package:lynko/features/chat/domain/entity/uploaded_media_entity.dart';

class UploadedMediaModel extends UploadedMediaEntity {
  const UploadedMediaModel({required super.url, super.fileName, super.fileSizeBytes});

  factory UploadedMediaModel.fromJson(Map<String, dynamic> json) {
    return UploadedMediaModel(
      url: json['url'] as String,
      fileName: json['fileName'] as String?,
      fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt(),
    );
  }
}