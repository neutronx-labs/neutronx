import 'package:recase/recase.dart';

/// Generator for service classes
class ServiceGenerator {
  final String name;

  ServiceGenerator(this.name);

  String generate() {
    final rc = ReCase(name);
    
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
}
