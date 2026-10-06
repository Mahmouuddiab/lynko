import 'package:dio/dio.dart';
import 'package:lynko/core/error/app_exception.dart';
import 'package:lynko/core/network/api_constant.dart';
import 'package:lynko/core/network/dio_helper.dart';
import 'package:lynko/features/chat/domain/entity/message_type.dart';
import '../models/message_model.dart';
import '../models/uploaded_media_model.dart';
import '../models/user_model.dart';

abstract class ChatRemoteDs {
  Future<List<UserModel>> allUsers();

  Future<MessageModel> sendMessage({
    required int receiverId,
    required String content,
  });

  Future<List<MessageModel>> getConversation(int otherUserId);

  Future<UploadedMediaModel> uploadMedia({
    required String path,
    required String fileName,
    required MessageType type,
    void Function(double progress)? onProgress,
  });

  Future<MessageModel> sendAttachment({
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

class ChatRemoteDsImpl implements ChatRemoteDs {
  /// The server answers 400 with { "error": "..." }; show that text when present.
  String _errorOf(dynamic data, String fallback) {
    if (data is Map && data['error'] != null) return data['error'].toString();
    return fallback;
  }

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
        data: {'receiverId': receiverId, 'content': content},
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

  @override
  Future<UploadedMediaModel> uploadMedia({
    required String path,
    required String fileName,
    required MessageType type,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        'type': type.value,
        'file': await MultipartFile.fromFile(path, filename: fileName),
      });

      final response = await DioHelper.postFormData(
        path: ApiConstants.upload,
        formData: formData,
        withAuth: true,
        sendTimeout: const Duration(minutes: 5),
        receiveTimeout: const Duration(minutes: 2),
        onSendProgress: (sent, total) {
          if (total > 0) onProgress?.call(sent / total);
        },
      );

      if (response.statusCode == 200) {
        return UploadedMediaModel.fromJson(
          response.data as Map<String, dynamic>,
        );
      }
      throw ServerException(_errorOf(response.data, 'failed to upload file'));
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<MessageModel> sendAttachment({
    required int receiverId,
    required MessageType type,
    String? mediaUrl,
    String? fileName,
    int? fileSizeBytes,
    int? durationSeconds,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final response = await DioHelper.post(
        path: ApiConstants.sendMessage,
        data: {
          'receiverId': receiverId,
          'type': type.value,
          if (mediaUrl != null) 'mediaUrl': mediaUrl,
          if (fileName != null) 'fileName': fileName,
          if (fileSizeBytes != null) 'fileSizeBytes': fileSizeBytes,
          if (durationSeconds != null) 'durationSeconds': durationSeconds,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
        },
        withAuth: true,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return MessageModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw ServerException(_errorOf(response.data, 'failed to send message'));
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
