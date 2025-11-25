import 'package:recase/recase.dart';

/// Generator for service classes
class ServiceGenerator {
  final String name;
  final bool useRepository;

  ServiceGenerator(
    this.name, {
    this.useRepository = true,
  });

  String generate() {
    final rc = ReCase(name);

    if (useRepository) {
      return '''
import '../repositories/${name}_repository.dart';

/// Service for ${rc.titleCase} business logic
class ${rc.pascalCase}Service {
  final ${rc.pascalCase}Repository _repository;

  ${rc.pascalCase}Service(this._repository);

  Future<List<Map<String, dynamic>>> getAll() async {
    // Add business logic here
    return _repository.findAll();
  }

  Future<Map<String, dynamic>?> getById(String id) async {
    // Add business logic here
    return _repository.findById(id);
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    // Add validation and business logic here
    _validateData(data);
    return _repository.create(data);
  }

  Future<Map<String, dynamic>?> update(String id, Map<String, dynamic> data) async {
    // Add validation and business logic here
    _validateData(data);
    return _repository.update(id, data);
  }

  Future<bool> delete(String id) async {
    // Add business logic here (e.g., check permissions)
    return _repository.delete(id);
  }

  void _validateData(Map<String, dynamic> data) {
    // Add validation logic here
    if (data['name'] == null || (data['name'] as String).isEmpty) {
      throw ArgumentError('Name is required');
    }
  }
}
''';
    }

    return '''
/// Service for ${rc.titleCase} business logic
class ${rc.pascalCase}Service {
  Future<List<Map<String, dynamic>>> getAll() async {
    // TODO: implement data fetch
    return [];
  }

  Future<Map<String, dynamic>?> getById(String id) async {
    // TODO: implement fetch by id
    return null;
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    // TODO: implement create logic
    return data;
  }

  Future<Map<String, dynamic>?> update(String id, Map<String, dynamic> data) async {
    // TODO: implement update logic
    return {'id': id, ...data};
  }

  Future<bool> delete(String id) async {
    // TODO: implement delete logic
    return true;
  }
}
''';
  }
}
