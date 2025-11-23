import 'package:models/models.dart';

/// User repository - handles user data storage and retrieval
///
/// This is a simple in-memory implementation for demonstration.
/// In production, this would connect to a real database.
class UsersRepository {
  final Map<String, UserDto> _users = {};

  UsersRepository() {
    // Seed some initial data
    _users['1'] = UserDto(
      id: '1',
      name: 'Alice Johnson',
      email: 'alice@example.com',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    );
    _users['2'] = UserDto(
      id: '2',
      name: 'Bob Smith',
      email: 'bob@example.com',
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
    );
  }

  List<UserDto> findAll() {
    return _users.values.toList();
  }

  UserDto? findById(String id) {
    return _users[id];
  }

  UserDto create(String name, String email) {
    final id = ((_users.length + 1).toString());
    final user = UserDto(
      id: id,
      name: name,
      email: email,
      createdAt: DateTime.now(),
    );
    _users[id] = user;
    return user;
  }

  UserDto? update(String id, {String? name, String? email}) {
    final user = _users[id];
    if (user == null) return null;

    final updated = UserDto(
      id: user.id,
      name: name ?? user.name,
      email: email ?? user.email,
      createdAt: user.createdAt,
    );
    _users[id] = updated;
    return updated;
  }

  bool delete(String id) {
    return _users.remove(id) != null;
  }
}
