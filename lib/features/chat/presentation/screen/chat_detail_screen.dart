import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lynko/features/chat/domain/entity/user_entity.dart';
import 'package:lynko/features/chat/presentation/providers/conversation_provider.dart';
import 'chat_screen.dart' show UserAvatar;

class ChatDetailScreen extends ConsumerStatefulWidget {
  final UserEntity user;

  const ChatDetailScreen({super.key, required this.user});

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen>
    with WidgetsBindingObserver {
  /// How often the open chat checks the server for new messages.
  static const _pollInterval = Duration(seconds: 3);

  final _controller = TextEditingController();
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Load the latest messages when the chat opens, then keep checking.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refresh();
      _startPolling();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poll?.cancel();
    _controller.dispose();
    super.dispose();
  }

  // Poll only while the app is in the foreground.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
      _startPolling();
    } else if (state == AppLifecycleState.paused) {
      _poll?.cancel();
      _poll = null;
    }
  }

  void _startPolling() {
    _poll?.cancel();
    _poll = Timer.periodic(_pollInterval, (_) {
      if (mounted) {
        ref
            .read(conversationsProvider.notifier)
            .syncRemoteConversation(widget.user.id);
      }
    });
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    ref
        .read(conversationsProvider.notifier)
        .send(receiverId: widget.user.id, content: text);
  }

  void _retry(ChatMessage message) {
    ref
        .read(conversationsProvider.notifier)
        .retry(receiverId: widget.user.id, id: message.id);
  }

  Future<void> _refresh() async {
    await ref
        .read(conversationsProvider.notifier)
        .syncRemoteConversation(widget.user.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final messages = ref.watch(conversationProvider(widget.user.id));

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            UserAvatar(name: widget.user.fullName, radius: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.user.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    widget.user.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator.adaptive(
              onRefresh: _refresh,
              child: messages.isEmpty
                  ? CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child:
                    _EmptyConversation(name: widget.user.fullName),
                  ),
                ],
              )
                  : ListView.builder(
                reverse: true,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final m = messages[index];
                  return _MessageBubble(
                    message: m,
                    onRetry: m.status == MessageStatus.failed
                        ? () => _retry(m)
                        : null,
                  );
                },
              ),
            ),
          ),
          _MessageInput(controller: _controller, onSend: _send),
        ],
      ),
    );
  }
}

// Sub-Widgets

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onRetry;

  const _MessageBubble({required this.message, this.onRetry});

  // Always show the time in the device's timezone.
  String get _time {
    final t = message.time.toLocal();
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mine = message.isMine;
    final bg = mine ? scheme.primary : scheme.surfaceContainerHighest;
    final fg = mine ? scheme.onPrimary : scheme.onSurface;
    final failed = message.status == MessageStatus.failed;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: onRetry,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.78,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(mine ? 18 : 4),
              bottomRight: Radius.circular(mine ? 4 : 18),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message.text,
                style: TextStyle(color: fg, fontSize: 15.5, height: 1.3),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (failed)
                    Text(
                      'Failed, tap to retry  ',
                      style: TextStyle(
                        color: mine ? Colors.red.shade100 : scheme.error,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  Text(
                    _time,
                    style: TextStyle(
                      color: fg.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                  if (mine) ...[
                    const SizedBox(width: 4),
                    Icon(
                      switch (message.status) {
                        MessageStatus.sending => Icons.schedule_rounded,
                        MessageStatus.sent => Icons.done_rounded,
                        MessageStatus.failed => Icons.error_outline_rounded,
                      },
                      size: 14,
                      color: failed
                          ? Colors.red.shade100
                          : fg.withValues(alpha: 0.7),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _MessageInput({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Message',
                  filled: true,
                  fillColor: scheme.surfaceContainerHighest.withValues(
                    alpha: 0.6,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (_, value, __) {
                final enabled = value.text.trim().isNotEmpty;
                return IconButton.filled(
                  onPressed: enabled ? onSend : null,
                  icon: const Icon(Icons.send_rounded),
                  style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyConversation extends StatelessWidget {
  final String name;

  const _EmptyConversation({required this.name});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            UserAvatar(name: name, radius: 36),
            const SizedBox(height: 16),
            Text(
              'Say hi to $name',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Your messages will appear here.',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}