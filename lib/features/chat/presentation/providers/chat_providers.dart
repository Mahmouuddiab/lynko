import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lynko/features/chat/data/repository/chat_repository_impl.dart';
import 'package:lynko/features/chat/domain/entity/message_entity.dart';
import 'package:lynko/features/chat/domain/entity/user_entity.dart';
import 'package:lynko/features/chat/domain/repository/chat_repository.dart';
import 'package:lynko/features/chat/domain/usecase/all_users_usecase.dart';
import 'package:lynko/features/chat/domain/usecase/get_conversation_usecase.dart';
import 'package:lynko/features/chat/domain/usecase/send_message_use_case.dart';
import '../../data/data source/chat_remote_ds.dart';

// ==========================================
// Data & Repository Providers
// ==========================================

final chatRemoteDsProvider = Provider<ChatRemoteDs>((ref) {
  return ChatRemoteDsImpl();
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final remoteDs = ref.watch(chatRemoteDsProvider);
  return ChatRepositoryImpl(remoteDs);
});

// ==========================================
// Use Case Providers
// ==========================================

final allUsersUseCaseProvider = Provider<AllUsersUseCase>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return AllUsersUseCase(repository);
});

final sendMessageUseCaseProvider = Provider<SendMessageUseCase>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return SendMessageUseCase(repository);
});

final getConversationUseCaseProvider = Provider<GetConversationUseCase>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return GetConversationUseCase(repository);
});

// ==========================================
// Presentation / State Providers
// ==========================================

final allUsersProvider = FutureProvider<List<UserEntity>>((ref) {
  final useCase = ref.watch(allUsersUseCaseProvider);
  return useCase.call();
});

// Fetches conversation history dynamically for a given user ID
final conversationProvider =
FutureProvider.family<List<MessageEntity>, int>((ref, otherUserId) {
  final useCase = ref.watch(getConversationUseCaseProvider);
  return useCase.call(otherUserId);
});

class SendMessageNotifier extends Notifier<AsyncValue<MessageEntity?>> {
  int _inFlight = 0;

  @override
  AsyncValue<MessageEntity?> build() => const AsyncValue.data(null);

  Future<MessageEntity?> sendMessage({
    required int receiverId,
    required String content,
  }) async {
    final text = content.trim();
    if (text.isEmpty) return null;

    final useCase = ref.read(sendMessageUseCaseProvider);

    _inFlight++;
    state = const AsyncValue.loading();

    try {
      final message = await useCase.call(receiverId: receiverId, content: text);
      // Only the last running send flips the state back to "idle".
      if (_inFlight == 1) state = AsyncValue.data(message);

      // Auto-refresh conversation history after successfully sending a message
      ref.invalidate(conversationProvider(receiverId));

      return message;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    } finally {
      _inFlight--;
    }
  }
}

final sendMessageNotifierProvider =
NotifierProvider<SendMessageNotifier, AsyncValue<MessageEntity?>>(
  SendMessageNotifier.new,
);