import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lynko/core/cache/cache_helper.dart';
import 'package:lynko/core/router/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const _logoPath = 'assets/logo.png';
  static const String? _tagline = null;

  late final AnimationController _intro;
  late final AnimationController _glow;

  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _textSpacing;
  late final Animation<double> _taglineFade;
  late final Animation<double> _progress;
  late final Animation<double> _barFade;

  @override
  void initState() {
    super.initState();

    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    Animation<double> interval(double a, double b, Curve c) =>
        CurvedAnimation(parent: _intro, curve: Interval(a, b, curve: c));

    _logoFade = interval(0.0, 0.35, Curves.easeOut);
    _logoScale = Tween<double>(begin: 0.6, end: 1.0)
        .animate(interval(0.0, 0.5, Curves.easeOutBack));

    _textFade = interval(0.35, 0.65, Curves.easeOut);
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero)
        .animate(interval(0.35, 0.65, Curves.easeOutCubic));
    _textSpacing = Tween<double>(begin: 10, end: 3)
        .animate(interval(0.35, 0.8, Curves.easeOutCubic));

    _taglineFade = interval(0.6, 0.85, Curves.easeOut);

    _barFade = interval(0.3, 0.5, Curves.easeIn);
    _progress = interval(0.3, 1.0, Curves.easeInOut);

    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    if (!mounted) return;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    await precacheImage(const AssetImage(_logoPath), context);
    if (!mounted) return;

    final routeFuture = _resolveRoute();

    try {
      if (reduceMotion) {
        _intro.value = 1;
      } else {
        _glow.repeat(reverse: true);
        await _intro.forward().orCancel;
      }
    } on TickerCanceled {
      return;
    }

    final route = await routeFuture;
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    Navigator.of(context).pushReplacementNamed(route);
  }

  Future<String> _resolveRoute() async {
     final token = await  CacheHelper.getToken();
     return token != null ? AppRoutes.main : AppRoutes.login;
  }

  @override
  void dispose() {
    _intro.dispose();
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
          .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? const [Color(0xFF0F1115), Color(0xFF1A1D24)]
                  : [Colors.white, primary.withValues(alpha: 0.06)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),

                FadeTransition(
                  opacity: _logoFade,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: AnimatedBuilder(
                      animation: _glow,
                      builder: (_, child) {
                        final t = Curves.easeInOut.transform(_glow.value);
                        return Container(
                          width: 220.w,
                          height: 220.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                primary.withValues(alpha: 0.08 + 0.10 * t),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: child,
                        );
                      },
                      child: Center(
                        child: Image.asset(
                          _logoPath,
                          width: 110.w,
                          height: 110.w,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 8.h),


                FadeTransition(
                  opacity: _textFade,
                  child: SlideTransition(
                    position: _textSlide,
                    child: AnimatedBuilder(
                      animation: _textSpacing,
                      builder: (_, __) => Text(
                        'LYNKO',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontSize: 30.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: _textSpacing.value,
                        ),
                      ),
                    ),
                  ),
                ),

                if (_tagline != null) ...[
                  SizedBox(height: 10.h),
                  FadeTransition(
                    opacity: _taglineFade,
                    child: Text(
                      _tagline!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14.sp,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],

                const Spacer(flex: 3),

                FadeTransition(
                  opacity: _barFade,
                  child: AnimatedBuilder(
                    animation: _progress,
                    builder: (_, __) => SizedBox(
                      width: 120.w,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4.r),
                        child: LinearProgressIndicator(
                          value: _progress.value,
                          minHeight: 3.h,
                          color: primary,
                          backgroundColor: primary.withValues(alpha: 0.15),
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 56.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}