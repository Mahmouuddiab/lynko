import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lynko/features/chat/domain/entity/user_entity.dart';
import 'package:lynko/features/chat/presentation/providers/chat_providers.dart';
import 'package:lynko/features/chat/presentation/providers/unread_providers.dart';
import 'package:lynko/features/chat/presentation/screen/chat_detail_screen.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshUnread();
    });
  }

  Future<void> _refreshUnread() async {
    try {
      final users = await ref.read(allUsersProvider.future);
      await ref
          .read(unreadCountsProvider.notifier)
          .refresh(users.map((u) => u.id).toList());
    } catch (_) {
      // The users list shows its own error state.
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<UserEntity> _filter(List<UserEntity> users) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return users;
    return users
        .where((u) =>
    u.fullName.toLowerCase().contains(q) ||
        u.email.toLowerCase().contains(q))
        .toList();
  }

  Future<void> _refresh() async {
    ref.invalidate(allUsersProvider);
    await ref.read(allUsersProvider.future);
    await _refreshUnread();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(allUsersProvider);
    final unreadCounts = ref.watch(unreadCountsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _SearchField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              onClear: () {
                _searchController.clear();
                setState(() => _query = '');
              },
            ),
            Expanded(
              child: usersAsync.when(
                data: (users) {
                  final filtered = _filter(users);
                  return RefreshIndicator.adaptive(
                    onRefresh: _refresh,
                    child: filtered.isEmpty
                        ? CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: users.isEmpty
                              ? const EmptyUsersWidget()
                              : EmptyUsersWidget(
                            title: 'No results',
                            subtitle:
                            'Nothing matches "${_query.trim()}"',
                            icon: Icons.search_off_rounded,
                          ),
                        ),
                      ],
                    )
                        : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final user = filtered[index];
                        return UserTile(
                          user: user,
                          unreadCount: unreadCounts[user.id] ?? 0,
                          onTap: () =>
                              _navigateToChatDetail(context, user),
                        );
                      },
                    ),
                  );
                },
                loading: () => const _SkeletonList(),
                error: (error, stackTrace) => ErrorViewWidget(
                  errorMessage: error.toString(),
                  onRetry: () => ref.invalidate(allUsersProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToChatDetail(
      BuildContext context,
      UserEntity user,
      ) async {
    final unread = ref.read(unreadCountsProvider.notifier);

    // Opening the chat marks it as read (locally and on the server).
    unread.markRead(user.id);

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatDetailScreen(user: user)),
    );

    // Anything that arrived while the chat was open was already seen.
    await unread.markRead(user.id);
  }
}

// Reusable Sub-Widgets

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search people',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, value, __) => value.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: onClear,
            ),
          ),
          filled: true,
          fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class UserTile extends StatelessWidget {
  final UserEntity user;
  final VoidCallback onTap;
  final int unreadCount;

  const UserTile({
    super.key,
    required this.user,
    required this.onTap,
    this.unreadCount = 0,
  });

  bool get _hasUnread => unreadCount > 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                UserAvatar(name: user.fullName),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight:
                          _hasUnread ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _hasUnread
                              ? scheme.onSurface
                              : scheme.onSurfaceVariant,
                          fontWeight:
                          _hasUnread ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (_hasUnread)
                  UnreadBadge(count: unreadCount)
                else
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 20,
                    color: scheme.primary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pill-shaped counter. Shows "99+" above 99.
class UnreadBadge extends StatelessWidget {
  final int count;

  const UnreadBadge({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = count > 99 ? '99+' : '$count';

    return Semantics(
      label: '$count unread messages',
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, animation) =>
            ScaleTransition(scale: animation, child: child),
        child: Container(
          key: ValueKey(label),
          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          padding: const EdgeInsets.symmetric(horizontal: 7),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: scheme.onPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
        ),
      ),
    );
  }
}

class UserAvatar extends StatelessWidget {
  final String name;
  final double radius;

  const UserAvatar({
    super.key,
    required this.name,
    this.radius = 26,
  });

  String get _initials {
    final parts =
    name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  // Stable color per user, derived from the name.
  Color get _color {
    final hue = (name.hashCode.abs() % 360).toDouble();
    return HSLColor.fromAHSL(1, hue, 0.55, 0.45).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final base = _color;

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [base, base.withValues(alpha: 0.7)],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.7,
        ),
      ),
    );
  }
}

class EmptyUsersWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;

  const EmptyUsersWidget({
    super.key,
    this.title = 'No users found',
    this.subtitle,
    this.icon = Icons.people_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primary.withValues(alpha: 0.08),
              ),
              child: Icon(icon, size: 48, color: scheme.primary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorViewWidget extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;

  const ErrorViewWidget({
    super.key,
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.error.withValues(alpha: 0.1),
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 48,
                color: scheme.error,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

// Loading skeleton

class _SkeletonList extends StatefulWidget {
  const _SkeletonList();

  @override
  State<_SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<_SkeletonList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final color = base.withValues(alpha: 0.4 + 0.4 * _controller.value);

        Widget block(double w, double h, {bool circle = false}) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: color,
            shape: circle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: circle ? null : BorderRadius.circular(6),
          ),
        );

        return ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          itemCount: 8,
          itemBuilder: (_, i) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                block(52, 52, circle: true),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    block(140 + (i % 3) * 20, 14),
                    const SizedBox(height: 8),
                    block(200, 12),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}