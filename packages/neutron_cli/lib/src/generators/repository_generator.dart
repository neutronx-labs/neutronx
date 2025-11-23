import 'package:recase/recase.dart';

/// Generator for repository classes
class RepositoryGenerator {
  final String name;

  RepositoryGenerator(this.name);

  String generate() {
    final rc = ReCase(name);
    
    return '''
/// Repository for ${rc.titleCase} data access
class ${rc.pascalCase}Repository {
  // In-memory storage (replace with your database)
  final Map<String, Map<String, dynamic>> _storage = {};
  int _idCounter = 1;

  Future<List<Map<String, dynamic>>> findAll() async {
    // TODO: Replace with database query
    return _storage.values.toList();
  }

  Future<Map<String, dynamic>?> findById(String id) async {
    // TODO: Replace with database query
    return _storage[id];
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    // TODO: Replace with database insert
    final id = (_idCounter++).toString();
    final item = {
      'id': id,
      ...data,
      'createdAt': DateTime.now().toIso8601String(),
    };
    _storage[id] = item;
    return item;
  }

  Future<Map<String, dynamic>?> update(String id, Map<String, dynamic> data) async {
    // TODO: Replace with database update
    if (!_storage.containsKey(id)) {
      return null;
    }
    
    final item = {
      ..._storage[id]!,
      ...data,
      'id': id,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    _storage[id] = item;
    return item;
  }

  Future<bool> delete(String id) async {
    // TODO: Replace with database delete
    if (!_storage.containsKey(id)) {
      return false;
    }
    _storage.remove(id);
    return true;
  }

  Future<List<Map<String, dynamic>>> findWhere(
    bool Function(Map<String, dynamic>) predicate,
  ) async {
    // TODO: Replace with database query
    return _storage.values.where(predicate).toList();
  }
}
''';
  }
}
