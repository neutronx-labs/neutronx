import 'package:models/models.dart';
import '../repositories/users_repository.dart';

/// User service - business logic layer
///
/// This is a stateless service that uses the repository for data access.
/// It's registered in the DI container and injected into route handlers.
class UsersService {
  final UsersRepository _repository;

  UsersService(this._repository);

  List<UserDto> getAllUsers() {
    return _repository.findAll();
  }

  UserDto? getUserById(String id) {
    return _repository.findById(id);
  }

  UserDto createUser(String name, String email) {
    // In a real app, you'd add validation here
    if (name.isEmpty || email.isEmpty) {
      throw ArgumentError('Name and email are required');
    }

    if (!email.contains('@')) {
      throw ArgumentError('Invalid email format');
    }

    return _repository.create(name, email);
  }

  UserDto? updateUser(String id, {String? name, String? email}) {
    return _repository.update(id, name: name, email: email);
  }

  bool deleteUser(String id) {
    return _repository.delete(id);
  }
}
