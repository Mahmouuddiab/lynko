import 'package:lynko/core/error/app_exception.dart';
import 'package:lynko/core/network/api_constant.dart';
import 'package:lynko/core/network/dio_helper.dart';
import 'package:lynko/core/params/register_params.dart';
import 'package:lynko/features/auth/data/models/register_model.dart';

abstract class AuthRemoteDs {
  Future<RegisterModel> register(RegisterParams registerParams);
}

class AuthRemoteDsImpl implements AuthRemoteDs {
  @override
  Future<RegisterModel> register(RegisterParams registerParams) async {
    try {
      final response = await DioHelper.post(
        path: ApiConstants.register,
        data: {
          "fullName": registerParams.name,
          "email": registerParams.email,
          "password": registerParams.password,
        },
      );
      if (response.statusCode == 200) {
        return RegisterModel.fromJson(response.data);
      } else {
        throw ServerException(
          response.data['message'] ?? 'Registration failed',
        );
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
