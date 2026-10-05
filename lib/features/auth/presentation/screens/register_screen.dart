import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lynko/core/params/register_params.dart';
import 'package:lynko/core/router/app_routes.dart';
import 'package:lynko/core/utils/app_colors.dart';
import 'package:lynko/core/validator/app_validator.dart';
import 'package:lynko/features/auth/presentation/providers/auth_providers.dart';
import 'package:lynko/features/auth/presentation/widgets/app_button.dart';
import 'package:lynko/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:lynko/shared/custom_snack_bar.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onRegisterPressed() {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState?.validate() ?? false) {
      ref
          .read(registerControllerProvider.notifier)
          .register(
        registerParams: RegisterParams(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(registerControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stackTrace) {
          CustomSnackBar.show(
            context,
            message: error.toString(),
            type: SnackBarType.error,
          );
        },
        data: (_) {
          if (previous?.isLoading ?? false) {
            CustomSnackBar.show(
              context,
              message: 'Registration Successful!',
              type: SnackBarType.success,
            );
            Navigator.pushNamed(context, AppRoutes.login);
          }
        },
      );
    });

    final registerState = ref.watch(registerControllerProvider);
    final isLoading = registerState.isLoading;

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
                        _buildLoginRow(),
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
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
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
          'Create an account',
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
          'Fill in your details to get started',
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
              label: 'Name',
              hint: 'Enter your full name',
              controller: _nameController,
              validator: (_) => AppValidator.name(_nameController.text),
            ),
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
              text: 'Register',
              isLoading: isLoading,
              onPressed: _onRegisterPressed,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account?',
          style: TextStyle(
            fontSize: 14.sp,
            color: AppColors.black.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(width: 6.w),
        GestureDetector(
          onTap: () {
            Navigator.pushReplacementNamed(context, AppRoutes.login);
          },
          child: Text(
            'Login',
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