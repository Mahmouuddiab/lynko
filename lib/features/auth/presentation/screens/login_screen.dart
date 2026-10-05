import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lynko/core/params/login_params.dart';
import 'package:lynko/core/router/app_routes.dart';
import 'package:lynko/core/utils/app_colors.dart';
import 'package:lynko/core/validator/app_validator.dart';
import 'package:lynko/features/auth/presentation/providers/auth_providers.dart';
import 'package:lynko/features/auth/presentation/widgets/app_button.dart';
import 'package:lynko/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:lynko/shared/custom_snack_bar.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLoginPressed() {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState?.validate() ?? false) {
      final params = LoginParams(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      ref.read(loginControllerProvider.notifier).login(loginParams: params);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue>(loginControllerProvider, (previous, next) {
      if (previous?.isLoading == true && !next.isLoading) {
        next.when(
          data: (_) {
            CustomSnackBar.show(
              context,
              message: 'Login Successful!',
              type: SnackBarType.success,
            );
            Navigator.pushReplacementNamed(context, AppRoutes.main);
          },
          error: (error, stackTrace) {
            CustomSnackBar.show(
              context,
              message: error.toString(),
              type: SnackBarType.error,
            );
          },
          loading: () {},
        );
      }
    });

    final loginState = ref.watch(loginControllerProvider);
    final isLoading = loginState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.transparent,
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset('assets/background.png', fit: BoxFit.cover),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 24.h,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(),
                        SizedBox(height: 28.h),
                        _buildFormCard(isLoading),
                        SizedBox(height: 24.h),
                        _buildRegisterRow(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 76.w,
          height: 76.w,
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(22.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.25),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Image.asset('assets/logo.png', fit: BoxFit.contain),
        ),
        SizedBox(height: 22.h),
        Text(
          'Welcome back',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28.sp,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: AppColors.black,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'Login with your email to continue',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.black.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard(bool isLoading) {
    return Container(
      padding: EdgeInsets.all(22.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(color: Colors.white.withOpacity(0.9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AuthTextField(
              label: 'Email',
              hint: 'Enter your email',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: (_) => AppValidator.email(_emailController.text),
            ),
            AuthTextField(
              label: 'Password',
              hint: 'Enter your password',
              controller: _passwordController,
              isPassword: true,
              validator: (_) => AppValidator.password(_passwordController.text),
            ),
            SizedBox(height: 16.h),
            AuthButton(
              text: 'Login',
              isLoading: isLoading,
              onPressed: _onLoginPressed,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account?",
          style: TextStyle(
            fontSize: 14.sp,
            color: AppColors.black.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(width: 6.w),
        GestureDetector(
          onTap: () {
            Navigator.pushReplacementNamed(context, AppRoutes.register);
          },
          child: Text(
            'Register',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}