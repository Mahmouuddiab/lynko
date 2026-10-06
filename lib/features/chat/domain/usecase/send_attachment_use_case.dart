import 'package:lynko/features/chat/domain/entity/message_entity.dart';
import 'package:lynko/features/chat/domain/entity/message_type.dart';
import 'package:lynko/features/chat/domain/repository/chat_repository.dart';

class SendAttachmentUseCase {
  final ChatRepository repo;

  const SendAttachmentUseCase(this.repo);

  /// Image, video or file: upload first, then send a message that carries the URL.
  Future<MessageEntity> media({
    required int receiverId,
    required String path,
    required String fileName,
    required MessageType type,
    int? durationSeconds,
    void Function(double progress)? onProgress,
  }) async {
    final up = await repo.uploadMedia(
      path: path,
      fileName: fileName,
      type: type,
      onProgress: onProgress,
    );

    final isFile = type == MessageType.file;
    return repo.sendAttachment(
      receiverId: receiverId,
      type: type,
      mediaUrl: up.url,
      fileName: isFile ? (up.fileName ?? fileName) : null,
      fileSizeBytes: isFile ? up.fileSizeBytes : null,
      durationSeconds: durationSeconds,
    );
  }

  Future<MessageEntity> location({
    required int receiverId,
    required double latitude,
    required double longitude,
  }) {
    return repo.sendAttachment(
      receiverId: receiverId,
      type: MessageType.location,
      latitude: latitude,
      longitude: longitude,
    );
  }
}