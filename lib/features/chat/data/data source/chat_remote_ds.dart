import 'package:lynko/core/error/app_exception.dart';
import 'package:lynko/core/network/api_constant.dart';
import 'package:lynko/core/network/dio_helper.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';

abstract class ChatRemoteDs {
  Future<List<UserModel>> allUsers();
  Future<MessageModel> sendMessage({
    required int receiverId,
    required String content,
  });
  Future<List<MessageModel>> getConversation(int otherUserId);
}

class ChatRemoteDsImpl implements ChatRemoteDs {
  @override
  Future<List<UserModel>> allUsers() async {
    try {
      final response = await DioHelper.get(
        path: ApiConstants.allUsers,
        withAuth: true,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data
            .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw const ServerException('failed to get users');
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<MessageModel> sendMessage({
    required int receiverId,
    required String content,
  }) async {
    try {
      final response = await DioHelper.post(
        path: ApiConstants.sendMessage,
        data: {
          'receiverId': receiverId,
          'content': content,
        },
        withAuth: true,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return MessageModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw const ServerException('failed to send message');
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<MessageModel>> getConversation(int otherUserId) async {
    try {
      final response = await DioHelper.get(
        path: ApiConstants.getMessage(otherUserId),
        withAuth: true,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data
            .map((json) => MessageModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw const ServerException('failed to get conversation');
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}