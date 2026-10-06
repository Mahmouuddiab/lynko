import 'package:lynko/features/chat/domain/entity/message_entity.dart';
import 'package:lynko/features/chat/domain/entity/message_type.dart';
import 'package:lynko/features/chat/domain/entity/uploaded_media_entity.dart';
import 'package:lynko/features/chat/domain/entity/user_entity.dart';

abstract class ChatRepository {
  Future<List<UserEntity>> allUsers();

  Future<MessageEntity> sendMessage({
    required int receiverId,
    required String content,
  });

  Future<List<MessageEntity>> getConversation(int otherUserId);

  Future<UploadedMediaEntity> uploadMedia({
    required String path,
    required String fileName,
    required MessageType type,
    void Function(double progress)? onProgress,
  });

  Future<MessageEntity> sendAttachment({
    required int receiverId,
    required MessageType type,
    String? mediaUrl,
    String? fileName,
    int? fileSizeBytes,
    int? durationSeconds,
    double? latitude,
    double? longitude,
  });
}