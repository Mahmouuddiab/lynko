import 'package:lynko/features/chat/data/data%20source/chat_remote_ds.dart';
import 'package:lynko/features/chat/domain/entity/message_entity.dart';
import 'package:lynko/features/chat/domain/entity/user_entity.dart';
import 'package:lynko/features/chat/domain/repository/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDs remote;
  const ChatRepositoryImpl(this.remote);
  @override
  Future<List<UserEntity>> allUsers() async {
    return await remote.allUsers();
  }

  @override
  Future<MessageEntity> sendMessage({required int receiverId, required String content}) async{
    return await remote.sendMessage(receiverId: receiverId, content: content) ;
  }

  @override
  Future<List<MessageEntity>> getConversation(int otherUserId) async{
    return await remote.getConversation(otherUserId) ;
  }
}
