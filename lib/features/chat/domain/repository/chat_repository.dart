import 'package:lynko/features/chat/domain/entity/message_entity.dart';
import 'package:lynko/features/chat/domain/entity/user_entity.dart';

abstract class ChatRepository {
  Future<List<UserEntity>> allUsers();
  Future<MessageEntity> sendMessage({
    required int receiverId,
    required String content,
  });
  Future<List<MessageEntity>> getConversation(int otherUserId);
}
