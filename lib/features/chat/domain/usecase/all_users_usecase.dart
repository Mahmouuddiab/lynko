import 'package:lynko/features/chat/domain/repository/chat_repository.dart';
import '../entity/user_entity.dart';

class AllUsersUseCase {
  final ChatRepository repo;
  const AllUsersUseCase(this.repo);
  Future<List<UserEntity>> call() => repo.allUsers();
}
