import 'package:lynko/features/chat/domain/entity/message_entity.dart';
import 'package:lynko/features/chat/domain/repository/chat_repository.dart';

class GetConversationUseCase {
  final ChatRepository repo;

  const GetConversationUseCase(this.repo);

  Future<List<MessageEntity>> call(int otherUserId) async {
    return await repo.getConversation(otherUserId);
  }
}