import 'package:equatable/equatable.dart';

class MessageEntity extends Equatable {
  final int id;
  final int senderId;
  final int receiverId;
  final String content;
  final DateTime sentAt;
  final bool isRead;

  const MessageEntity({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.sentAt,
    required this.isRead,
  });

  @override
  List<Object?> get props => [
    id,
    senderId,
    receiverId,
    content,
    sentAt,
    isRead,
  ];
}
