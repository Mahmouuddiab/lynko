import 'package:lynko/features/chat/domain/entity/message_entity.dart';
import 'package:lynko/features/chat/domain/repository/chat_repository.dart';

class SendMessageUseCase {
  final ChatRepository repo;

  const SendMessageUseCase(this.repo);

  Future<MessageEntity> call({
    required int receiverId,
    required String content,
  }) async {
    return await repo.sendMessage(receiverId: receiverId, content: content);
  }
}
