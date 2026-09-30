import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lynko/core/router/app_routes.dart';
import 'package:lynko/shared/splash_screen.dart';

void main() {
  testWidgets('Splash shows app name then navigates to login',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(390, 844),
            builder: (_, __) => MaterialApp(
              home: const SplashScreen(),
              routes: {
                AppRoutes.login: (_) =>
                const Scaffold(body: Center(child: Text('login-page'))),
              },
            ),
          ),
        );

        // Let the post-frame callback run.
        await tester.pump();

        // precacheImage needs real async work (asset loading) to finish.
        await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 200)),
        );

        // Mid-animation: the app name is on screen.
        await tester.pump(const Duration(milliseconds: 1500));
        expect(find.text('LYNKO'), findsOneWidget);

        // Finish the intro animation and the 350ms hold before navigating.
        await tester.pump(const Duration(milliseconds: 1500));
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('login-page'), findsOneWidget);
      });
}