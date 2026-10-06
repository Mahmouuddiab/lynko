import 'package:lynko/features/chat/domain/entity/message_entity.dart';
import 'package:lynko/features/chat/domain/entity/message_type.dart';

class MessageModel extends MessageEntity {
  const MessageModel({
    required super.id,
    required super.senderId,
    required super.receiverId,
    required super.content,
    required super.sentAt,
    required super.isRead,
    super.type,
    super.mediaUrl,
    super.fileName,
    super.fileSizeBytes,
    super.durationSeconds,
    super.latitude,
    super.longitude,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as int,
      senderId: json['senderId'] as int,
      receiverId: json['receiverId'] as int,
      content: json['content'] as String? ?? '',
      sentAt: DateTime.parse(json['sentAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
      type: MessageType.fromValue(json['type'] as int? ?? 0),
      mediaUrl: json['mediaUrl'] as String?,
      fileName: json['fileName'] as String?,
      fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt(),
      durationSeconds: json['durationSeconds'] as int?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'sentAt': sentAt.toIso8601String(),
      'isRead': isRead,
      'type': type.value,
      'mediaUrl': mediaUrl,
      'fileName': fileName,
      'fileSizeBytes': fileSizeBytes,
      'durationSeconds': durationSeconds,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}