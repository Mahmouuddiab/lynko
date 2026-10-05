import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lynko/core/error/app_exception.dart';
import 'package:lynko/core/network/api_constant.dart';
import 'package:lynko/core/network/dio_helper.dart';

class UnreadCountsNotifier extends Notifier<Map<int, int>> {
  @override
  Map<int, int> build() => const {};

  Future<int?> _unreadFrom(int otherId) async {
    try {
      final res = await DioHelper.get(
        path: ApiConstants.getMessage(otherId),
        withAuth: true,
      );
      if (res.statusCode != 200 || res.data is! List) return null;

      final list = (res.data as List).cast<Map<String, dynamic>>();
      return list
          .where(
            (m) =>
                (m['senderId'] as num).toInt() == otherId &&
                m['isRead'] != true,
          )
          .length;
    } catch (_) {
      return null;
    }
  }

  Future<void> refresh(List<int> userIds) async {
    final counts = await Future.wait(userIds.map(_unreadFrom));

    final next = Map<int, int>.of(state);
    for (var i = 0; i < userIds.length; i++) {
      final count = counts[i];
      if (count == null) continue;
      if (count > 0) {
        next[userIds[i]] = count;
      } else {
        next.remove(userIds[i]);
      }
    }
    state = next;
  }

  Future<void> markRead(int otherId) async {
    clear(otherId);
    try {
      await DioHelper.post(
        path: ApiConstants.markAsRead(otherId),
        withAuth: true,
      );
    } catch (_) {
      throw ServerException();
    }
  }

  void setCounts(Map<int, int> counts) => state = Map.of(counts);

  void increment(int userId, [int by = 1]) {
    state = {...state, userId: (state[userId] ?? 0) + by};
  }

  void clear(int userId) {
    if (!state.containsKey(userId)) return;
    final next = Map<int, int>.of(state)..remove(userId);
    state = next;
  }
}

final unreadCountsProvider =
    NotifierProvider<UnreadCountsNotifier, Map<int, int>>(
      UnreadCountsNotifier.new,
    );

final totalUnreadProvider = Provider<int>((ref) {
  return ref.watch(unreadCountsProvider).values.fold(0, (a, b) => a + b);
});
