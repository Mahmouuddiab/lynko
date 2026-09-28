import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lynko/core/network/api_constant.dart';
import 'package:lynko/core/network/dio_helper.dart';
import 'package:lynko/core/router/app_router.dart';
import 'package:lynko/core/router/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  DioHelper.init(baseUrl: ApiConstants.baseUrl);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'Lynko App',
          debugShowCheckedModeBanner: false,
          initialRoute: AppRoutes.register,
          onGenerateRoute: AppRouter.generateRoute,
        );
      },
    );
  }
}
