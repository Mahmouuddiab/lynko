import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lynko/core/cache/cache_helper.dart';
import 'package:lynko/core/router/app_routes.dart';
import 'package:lynko/core/utils/app_colors.dart';
import 'package:lynko/features/profile/presentation/providers/profile_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _fullDate(DateTime date) {
    final d = date.toLocal();
    return '${d.day} ${_months[d.month - 1]} ${d.year}';
  }

  String _shortDate(DateTime date) {
    final d = date.toLocal();
    return '${_months[d.month - 1]} ${d.year}';
  }

  Future<void> _copyEmail(BuildContext context, String email) async {
    await Clipboard.setData(ClipboardData(text: email));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          content: const Text('Email copied'),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  void _showLanguageSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (ctx) {
        final current = context.locale.languageCode;
        Widget option(String code, String label) {
          final selected = current == code;
          return ListTile(
            title: Text(
              label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            trailing: selected
                ? Icon(Icons.check_circle_rounded, color: AppColors.primary)
                : null,
            onTap: () async {
              await context.setLocale(Locale(code));
              if (ctx.mounted) Navigator.pop(ctx);
            },
          );
        }

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: 12.h),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                option('en', 'English'),
                option('ar', 'العربية'),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Log out', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await CacheHelper.clearToken();
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
      AppRoutes.login,
          (_) => false,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileNotifierProvider);

    Future<void> refresh() =>
        ref.read(profileNotifierProvider.notifier).refreshProfile();

    return Scaffold(
      body: profileAsync.when(
        loading: () => const _ProfileSkeleton(),
        error: (error, _) => _ErrorView(
          message: error.toString(),
          onRetry: refresh,
        ),
        data: (profile) {
          final initial = profile.fullName.isNotEmpty
              ? profile.fullName[0].toUpperCase()
              : '?';
          final days =
              DateTime.now().difference(profile.createdAt.toLocal()).inDays;
          final topPadding = MediaQuery.of(context).padding.top;

          return RefreshIndicator(
            onRefresh: refresh,
            edgeOffset: topPadding + 16.h,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              child: Column(
                children: [
                  // ───────── Header + floating stats card ─────────
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: double.infinity,
                        clipBehavior: Clip.antiAlias,
                        padding: EdgeInsets.fromLTRB(
                          20.w,
                          topPadding + 28.h,
                          20.w,
                          64.h,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primary,
                              Color.lerp(
                                AppColors.primary,
                                Colors.black,
                                0.25,
                              )!,
                            ],
                          ),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(36.r),
                            bottomRight: Radius.circular(36.r),
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.topCenter,
                          children: [
                            // decorative circles
                            Positioned(
                              top: -70.h,
                              right: -50.w,
                              child: _Circle(size: 190.r, alpha: 0.08),
                            ),
                            Positioned(
                              bottom: -60.h,
                              left: -40.w,
                              child: _Circle(size: 150.r, alpha: 0.06),
                            ),
                            Column(
                              children: [
                                _Reveal(
                                  index: 0,
                                  child: Container(
                                    padding: EdgeInsets.all(4.r),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white,
                                          Colors.white.withValues(alpha: 0.3),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.2),
                                          blurRadius: 20.r,
                                          offset: Offset(0, 8.h),
                                        ),
                                      ],
                                    ),
                                    child: CircleAvatar(
                                      radius: 46.r,
                                      backgroundColor: AppColors.white,
                                      child: Text(
                                        initial,
                                        style: TextStyle(
                                          fontSize: 36.sp,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 16.h),
                                _Reveal(
                                  index: 1,
                                  child: Text(
                                    profile.fullName,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 24.sp,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 10.h),
                                _Reveal(
                                  index: 2,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 14.w,
                                      vertical: 6.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                      Colors.white.withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(20.r),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.alternate_email_rounded,
                                          size: 14.sp,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 6.w),
                                        Flexible(
                                          child: Text(
                                            profile.email,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 13.sp,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // refresh button
                            Positioned(
                              top: -14.h,
                              right: -8.w,
                              child: IconButton(
                                onPressed: refresh,
                                icon: const Icon(
                                  Icons.refresh_rounded,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // floating stats card
                      Positioned(
                        left: 20.w,
                        right: 20.w,
                        bottom: -36.h,
                        child: _Reveal(
                          index: 3,
                          child: _StatsCard(
                            items: [
                              _StatData(
                                label: 'Member since',
                                value: _shortDate(profile.createdAt),
                              ),
                              _StatData(
                                label: 'Days with Lynko',
                                value: '${days < 0 ? 0 : days}',
                              ),
                              const _StatData(
                                label: 'Status',
                                value: 'Active',
                                dotColor: Color(0xFF22C55E),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 60.h),

                  // ───────── Sections ─────────
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Column(
                      children: [
                        _Reveal(
                          index: 4,
                          child: _Section(
                            title: 'Account',
                            children: [
                              _SettingsTile(
                                icon: Icons.person_outline_rounded,
                                label: 'Full name',
                                value: profile.fullName,
                              ),
                              _SettingsTile(
                                icon: Icons.email_outlined,
                                label: 'Email',
                                value: profile.email,
                                trailing: Icon(
                                  Icons.copy_rounded,
                                  size: 18.sp,
                                  color: Colors.grey,
                                ),
                                onTap: () =>
                                    _copyEmail(context, profile.email),
                              ),
                              _SettingsTile(
                                icon: Icons.calendar_today_outlined,
                                label: 'Joined',
                                value: _fullDate(profile.createdAt),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20.h),
                        _Reveal(
                          index: 5,
                          child: _Section(
                            title: 'Preferences',
                            children: [
                              _SettingsTile(
                                icon: Icons.language_rounded,
                                label: 'Language',
                                value: context.locale.languageCode == 'ar'
                                    ? 'العربية'
                                    : 'English',
                                trailing: Icon(
                                  Icons.chevron_right_rounded,
                                  size: 22.sp,
                                  color: Colors.grey,
                                ),
                                onTap: () => _showLanguageSheet(context),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 28.h),
                        _Reveal(
                          index: 6,
                          child: SizedBox(
                            width: double.infinity,
                            height: 54.h,
                            child: FilledButton.icon(
                              onPressed: () => _confirmLogout(context),
                              icon: Icon(Icons.logout_rounded, size: 20.sp),
                              label: Text(
                                'Log out',
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor:
                                AppColors.error.withValues(alpha: 0.1),
                                foregroundColor: AppColors.error,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16.r),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 28.h),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ═════════════════════ Reusable pieces ═════════════════════

/// Fade + slide-up entrance, staggered by [index].
class _Reveal extends StatelessWidget {
  final int index;
  final Widget child;

  const _Reveal({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 450 + index * 90),
      curve: Curves.easeOutCubic,
      builder: (_, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 24),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class _Circle extends StatelessWidget {
  final double size;
  final double alpha;

  const _Circle({required this.size, required this.alpha});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: alpha),
      ),
    );
  }
}

class _StatData {
  final String label;
  final String value;
  final Color? dotColor;

  const _StatData({required this.label, required this.value, this.dotColor});
}

class _StatsCard extends StatelessWidget {
  final List<_StatData> items;

  const _StatsCard({required this.items});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 8.w),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 20.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (int i = 0; i < items.length; i++) ...[
              Expanded(child: _StatItem(data: items[i])),
              if (i != items.length - 1)
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: scheme.outlineVariant.withValues(alpha: 0.5),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final _StatData data;

  const _StatItem({required this.data});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (data.dotColor != null) ...[
              Container(
                width: 8.r,
                height: 8.r,
                decoration: BoxDecoration(
                  color: data.dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 6.w),
            ],
            Flexible(
              child: Text(
                data.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        Text(
          data.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11.sp,
            color: scheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 6.w, bottom: 8.h),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: scheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i != children.length - 1)
                  Divider(
                    height: 1,
                    indent: 64.w,
                    color: scheme.outlineVariant.withValues(alpha: 0.4),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, size: 20.sp, color: AppColors.primary),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: scheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[SizedBox(width: 8.w), trailing!],
          ],
        ),
      ),
    );
  }
}

// ═════════════════════ Loading skeleton ═════════════════════

class _ProfileSkeleton extends StatefulWidget {
  const _ProfileSkeleton();

  @override
  State<_ProfileSkeleton> createState() => _ProfileSkeletonState();
}

class _ProfileSkeletonState extends State<_ProfileSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _box(double w, double h, {double radius = 12}) {
    final base = Theme.of(context).colorScheme.onSurface;
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: base.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return FadeTransition(
      opacity: Tween(begin: 0.45, end: 1.0).animate(_c),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16.w, top + 28.h, 16.w, 16.h),
        child: Column(
          children: [
            _box(100.r, 100.r, radius: 100.r),
            SizedBox(height: 18.h),
            _box(180.w, 22.h),
            SizedBox(height: 10.h),
            _box(140.w, 16.h, radius: 20.r),
            SizedBox(height: 36.h),
            _box(double.infinity, 76.h, radius: 20.r),
            SizedBox(height: 24.h),
            _box(double.infinity, 190.h, radius: 20.r),
            SizedBox(height: 20.h),
            _box(double.infinity, 70.h, radius: 20.r),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════ Error state ═════════════════════

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_off_rounded,
                size: 44.sp,
                color: AppColors.error,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'Something went wrong',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 24.h),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(
                  horizontal: 24.w,
                  vertical: 14.h,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}