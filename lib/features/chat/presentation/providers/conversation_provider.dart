import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lynko/features/chat/domain/entity/message_entity.dart';
import 'package:lynko/features/chat/domain/entity/message_type.dart';
import 'package:lynko/features/chat/presentation/services/attachment_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'chat_providers.dart';

enum MessageStatus { sending, sent, failed }

/// The server stores UTC, but the timestamp often arrives without a "Z", so
/// Dart reads it as local time and it shows 3 hours early in Riyadh.
/// This always treats the clock fields as UTC and converts to device time.
DateTime serverTimeToLocal(DateTime t) {
  if (t.isUtc) return t.toLocal();
  return DateTime.utc(
    t.year,
    t.month,
    t.day,
    t.hour,
    t.minute,
    t.second,
    t.millisecond,
    t.microsecond,
  ).toLocal();
}

/// A message as shown in the chat UI.
class ChatMessage {
  /// Local key used by the UI. Server messages use `srv_<serverId>`.
  final String id;

  /// The server's id once the message is known to the server.
  final int? serverId;

  /// Text body (empty for media / location messages).
  final String text;
  final DateTime time;
  final bool isMine;
  final MessageStatus status;

  final MessageType type;
  final String? mediaUrl;

  /// Path on this device, kept so a failed upload can be retried and the
  /// preview shows instantly while uploading.
  final String? localPath;
  final String? fileName;
  final int? fileSizeBytes;
  final int? durationSeconds;
  final double? latitude;
  final double? longitude;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.time,
    required this.isMine,
    this.serverId,
    this.status = MessageStatus.sending,
    this.type = MessageType.text,
    this.mediaUrl,
    this.localPath,
    this.fileName,
    this.fileSizeBytes,
    this.durationSeconds,
    this.latitude,
    this.longitude,
  });

  bool get isUploadType =>
      type == MessageType.image ||
          type == MessageType.video ||
          type == MessageType.file ||
          type == MessageType.voice;

  /// Short text for the chat list / notifications.
  String get preview => switch (type) {
    MessageType.text => text,
    MessageType.image => '📷 Photo',
    MessageType.video => '🎥 Video',
    MessageType.voice => '🎤 Voice message',
    MessageType.location => '📍 Location',
    MessageType.file => '📎 ${fileName ?? 'File'}',
  };

  ChatMessage copyWith({MessageStatus? status, int? serverId}) => ChatMessage(
    id: id,
    serverId: serverId ?? this.serverId,
    text: text,
    time: time,
    isMine: isMine,
    status: status ?? this.status,
    type: type,
    mediaUrl: mediaUrl,
    localPath: localPath,
    fileName: fileName,
    fileSizeBytes: fileSizeBytes,
    durationSeconds: durationSeconds,
    latitude: latitude,
    longitude: longitude,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'serverId': serverId,
    'text': text,
    'time': time.toIso8601String(),
    'isMine': isMine,
    'status': status.name,
    'type': type.value,
    'mediaUrl': mediaUrl,
    'localPath': localPath,
    'fileName': fileName,
    'fileSizeBytes': fileSizeBytes,
    'durationSeconds': durationSeconds,
    'latitude': latitude,
    'longitude': longitude,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final saved = MessageStatus.values.firstWhere(
          (s) => s.name == json['status'],
      orElse: () => MessageStatus.sent,
    );

    return ChatMessage(
      id: json['id'] as String,
      serverId: json['serverId'] as int?,
      text: json['text'] as String,
      time: DateTime.parse(json['time'] as String),
      isMine: json['isMine'] as bool,
      // A message still "sending" when the app was closed never finished.
      status: saved == MessageStatus.sending ? MessageStatus.failed : saved,
      type: MessageType.fromValue(json['type'] as int? ?? 0),
      mediaUrl: json['mediaUrl'] as String?,
      localPath: json['localPath'] as String?,
      fileName: json['fileName'] as String?,
      fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt(),
      durationSeconds: json['durationSeconds'] as int?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}

/// Upload progress (0..1) per local message id. Kept out of the saved
/// conversation state so progress ticks don't rewrite the cache.
class UploadProgressNotifier extends Notifier<Map<String, double>> {
  @override
  Map<String, double> build() => const {};

  void set(String id, double progress) {
    final old = state[id];
    if (old != null && (progress - old).abs() < 0.01 && progress < 1) return;
    state = {...state, id: progress};
  }

  void remove(String id) {
    if (!state.containsKey(id)) return;
    state = {...state}..remove(id);
  }
}

final uploadProgressProvider =
NotifierProvider<UploadProgressNotifier, Map<String, double>>(
  UploadProgressNotifier.new,
);

// ==========================================
// ADAPT HERE (1 of 2): how to load a conversation from the server.
// Must return every message between me and [otherUserId].
// ==========================================
final remoteMessagesFetcherProvider =
Provider<Future<List<MessageEntity>> Function(int otherUserId)>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return (otherUserId) => repository.getConversation(otherUserId);
});

/// Keeps every conversation in memory (keyed by the other user's id), saves
/// it on the device, and reconciles it with the server.
/// Each list is ordered newest first.
class ConversationsNotifier extends Notifier<Map<int, List<ChatMessage>>> {
  // v2: the old cache could contain server messages saved with the wrong
  // side and a 3-hour time shift, so it is discarded.
  static const _storageKey = 'lynko_conversations_v2';
  static const _maxPerConversation = 500;

  /// A local message and a server message count as the same one when the
  /// type and text match and they were created within this window.
  static const _matchWindow = Duration(minutes: 2);

  @override
  Map<int, List<ChatMessage>> build() {
    unawaited(_load());
    return const {};
  }

  // ---------- Sending ----------

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  void _add(int receiverId, ChatMessage message) {
    _emit({
      ...state,
      receiverId: [message, ...?state[receiverId]],
    });
  }

  Future<void> send({
    required int receiverId,
    required String content,
  }) async {
    final text = content.trim();
    if (text.isEmpty) return;

    final message = ChatMessage(
      id: _newId(),
      text: text,
      time: DateTime.now(),
      isMine: true,
    );

    _add(receiverId, message);
    await _deliver(receiverId, message);
  }

  /// Image, video or file already picked on the device.
  Future<void> sendAttachment({
    required int receiverId,
    required PickedAttachment file,
  }) async {
    final message = ChatMessage(
      id: _newId(),
      text: '',
      time: DateTime.now(),
      isMine: true,
      type: file.type,
      localPath: file.path,
      fileName: file.name,
      fileSizeBytes: file.sizeBytes,
      durationSeconds: file.durationSeconds,
    );

    _add(receiverId, message);
    await _deliver(receiverId, message);
  }

  Future<void> sendLocation({
    required int receiverId,
    required double latitude,
    required double longitude,
  }) async {
    final message = ChatMessage(
      id: _newId(),
      text: '',
      time: DateTime.now(),
      isMine: true,
      type: MessageType.location,
      latitude: latitude,
      longitude: longitude,
    );

    _add(receiverId, message);
    await _deliver(receiverId, message);
  }

  Future<void> retry({required int receiverId, required String id}) async {
    final message = state[receiverId]?.where((m) => m.id == id).firstOrNull;
    if (message == null || message.status != MessageStatus.failed) return;
    await _deliver(receiverId, message);
  }

  Future<void> _deliver(int receiverId, ChatMessage message) async {
    _setStatus(receiverId, message.id, MessageStatus.sending);

    MessageEntity? result;
    try {
      result = await _request(receiverId, message);
    } catch (_) {
      result = null;
    }

    ref.read(uploadProgressProvider.notifier).remove(message.id);

    _setStatus(
      receiverId,
      message.id,
      result != null ? MessageStatus.sent : MessageStatus.failed,
      // ADAPT HERE (2 of 2): the server id field on MessageEntity.
      serverId: result?.id,
    );
  }

  Future<MessageEntity?> _request(int receiverId, ChatMessage m) async {
    switch (m.type) {
      case MessageType.text:
        return ref
            .read(sendMessageNotifierProvider.notifier)
            .sendMessage(receiverId: receiverId, content: m.text);

      case MessageType.location:
        return ref.read(sendAttachmentUseCaseProvider).location(
          receiverId: receiverId,
          latitude: m.latitude!,
          longitude: m.longitude!,
        );

      case MessageType.image:
      case MessageType.video:
      case MessageType.file:
      case MessageType.voice:
        final path = m.localPath;
        // The cached copy may be gone after an app restart.
        if (path == null || !File(path).existsSync()) return null;

        return ref.read(sendAttachmentUseCaseProvider).media(
          receiverId: receiverId,
          path: path,
          fileName: m.fileName ?? path.split('/').last,
          type: m.type,
          durationSeconds: m.durationSeconds,
          onProgress: (p) =>
              ref.read(uploadProgressProvider.notifier).set(m.id, p),
        );
    }
  }

  void _setStatus(
      int receiverId,
      String id,
      MessageStatus status, {
        int? serverId,
      }) {
    final list = state[receiverId];
    if (list == null) return;

    _emit({
      ...state,
      receiverId: [
        for (final m in list)
          m.id == id ? m.copyWith(status: status, serverId: serverId) : m,
      ],
    });
  }

  // ---------- Server sync ----------

  /// Loads the conversation from the server and merges it with local state:
  ///  * server messages are the source of truth;
  ///  * a message counts as mine when the other user is NOT its sender;
  ///  * my messages the server doesn't have yet (sending / failed) stay;
  ///  * my local copy of a message the server now has is dropped, so it
  ///    doesn't jump to the other side or show up twice.
  Future<void> syncRemoteConversation(int otherUserId) async {
    // Polling can fire while the previous request is still running.
    if (!_syncing.add(otherUserId)) return;
    try {
      await _syncRemoteConversation(otherUserId);
    } finally {
      _syncing.remove(otherUserId);
    }
  }

  final _syncing = <int>{};

  Future<void> _syncRemoteConversation(int otherUserId) async {
    final List<MessageEntity> remote;
    try {
      remote = await ref.read(remoteMessagesFetcherProvider)(otherUserId);
    } catch (_) {
      return; // Offline or server error: keep what is cached.
    }

    final fromServer = [
      for (final e in remote) _fromEntity(e, otherUserId),
    ];

    final local = state[otherUserId] ?? const <ChatMessage>[];

    // Server messages already linked to a local one.
    final claimed = <int>{
      for (final m in local)
        if (m.serverId != null) m.serverId!,
    };

    final stillPending = <ChatMessage>[];
    for (final m in local) {
      if (!m.isMine) continue; // Rebuilt from the server list below.
      if (m.serverId != null) continue; // The server copy replaces it.

      final match = fromServer
          .where((s) =>
      s.isMine &&
          !claimed.contains(s.serverId) &&
          s.type == m.type &&
          s.text == m.text &&
          s.time.difference(m.time).abs() < _matchWindow)
          .firstOrNull;

      if (match != null) {
        claimed.add(match.serverId!);
      } else {
        stillPending.add(m);
      }
    }

    final merged = [...stillPending, ...fromServer]
      ..sort((a, b) => b.time.compareTo(a.time));

    // Polling runs every few seconds: don't rebuild or save when nothing changed.
    if (_sameMessages(local, merged)) return;

    _emit({...state, otherUserId: merged});
  }

  bool _sameMessages(List<ChatMessage> a, List<ChatMessage> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id ||
          a[i].text != b[i].text ||
          a[i].status != b[i].status ||
          a[i].isMine != b[i].isMine) {
        return false;
      }
    }
    return true;
  }

  ChatMessage _fromEntity(MessageEntity e, int otherUserId) {
    return ChatMessage(
      id: 'srv_${e.id}',
      serverId: e.id,
      text: e.content,
      // ADAPT HERE if names differ: content / createdAt / senderId.
      time: serverTimeToLocal(e.sentAt),
      isMine: e.senderId != otherUserId,
      status: MessageStatus.sent,
      type: e.type,
      mediaUrl: e.mediaUrl,
      fileName: e.fileName,
      fileSizeBytes: e.fileSizeBytes,
      durationSeconds: e.durationSeconds,
      latitude: e.latitude,
      longitude: e.longitude,
    );
  }

  // ---------- Persistence ----------

  /// Call this on logout so the next account doesn't see these messages.
  Future<void> clear() async {
    state = const {};
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (_) {}
  }

  void _emit(Map<int, List<ChatMessage>> next) {
    state = {
      for (final e in next.entries)
        e.key: e.value.length > _maxPerConversation
            ? e.value.take(_maxPerConversation).toList()
            : e.value,
    };
    unawaited(_save());
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        for (final e in state.entries)
          '${e.key}': [for (final m in e.value) m.toJson()],
      };
      await prefs.setString(_storageKey, jsonEncode(data));
    } catch (_) {
      // Saving is best-effort; the in-memory state still works.
    }
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null) return;

      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final loaded = <int, List<ChatMessage>>{
        for (final e in decoded.entries)
          int.parse(e.key): [
            for (final m in e.value as List)
              ChatMessage.fromJson(m as Map<String, dynamic>),
          ],
      };

      // Keep anything already in memory (it is fresher) and add cached
      // messages that aren't in it yet.
      state = {
        for (final id in {...loaded.keys, ...state.keys})
          id: _combine(state[id] ?? const [], loaded[id] ?? const []),
      };
    } catch (_) {
      // Corrupt or unreadable data: start fresh instead of crashing.
    }
  }

  List<ChatMessage> _combine(List<ChatMessage> fresh, List<ChatMessage> cached) {
    final ids = {for (final m in fresh) m.id};
    return [
      ...fresh,
      ...cached.where((m) => !ids.contains(m.id)),
    ]..sort((a, b) => b.time.compareTo(a.time));
  }
}

final conversationsProvider =
NotifierProvider<ConversationsNotifier, Map<int, List<ChatMessage>>>(
  ConversationsNotifier.new,
);

/// Messages of one conversation (newest first). Rebuilds only when that
/// conversation changes.
final conversationProvider =
Provider.family<List<ChatMessage>, int>((ref, userId) {
  return ref.watch(
    conversationsProvider.select((all) => all[userId] ?? const <ChatMessage>[]),
  );
});