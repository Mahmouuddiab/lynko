import 'package:dio/dio.dart';
import 'package:lynko/core/error/app_exception.dart';
import 'package:lynko/core/network/api_constant.dart';
import 'package:lynko/core/network/dio_helper.dart';
import 'package:lynko/features/profile/data/model/profile_model.dart';

abstract class ProfileRemoteDs {
  Future<ProfileModel> getProfile();
}

class ProfileRemoteDsImpl implements ProfileRemoteDs {
  @override
  Future<ProfileModel> getProfile() async {
    try {
      final response = await DioHelper.get(
        path: ApiConstants.profile,
        withAuth: true,
      );

      if (response.statusCode == 200 && response.data != null) {
        return ProfileModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ServerException(
          response.statusMessage ?? 'Failed to load profile data',
        );
      }
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      final errorMessage =
          e.response?.data?['message']?.toString() ??
          e.message ??
          'Unexpected network error occurred';
      throw ServerException(errorMessage);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
