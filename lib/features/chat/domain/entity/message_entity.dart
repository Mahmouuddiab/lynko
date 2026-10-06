import 'package:equatable/equatable.dart';
import 'message_type.dart';

class MessageEntity extends Equatable {
  final int id;
  final int senderId;
  final int receiverId;
  final String content;
  final DateTime sentAt;
  final bool isRead;

  final MessageType type;
  final String? mediaUrl;
  final String? fileName;
  final int? fileSizeBytes;
  final int? durationSeconds;
  final double? latitude;
  final double? longitude;

  const MessageEntity({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.sentAt,
    required this.isRead,
    this.type = MessageType.text,
    this.mediaUrl,
    this.fileName,
    this.fileSizeBytes,
    this.durationSeconds,
    this.latitude,
    this.longitude,
  });

  @override
  List<Object?> get props => [
    id,
    senderId,
    receiverId,
    content,
    sentAt,
    isRead,
    type,
    mediaUrl,
    fileName,
    fileSizeBytes,
    durationSeconds,
    latitude,
    longitude,
  ];
}