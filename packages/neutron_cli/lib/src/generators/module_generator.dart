import 'package:recase/recase.dart';

/// Generator for NeutronX modules
class ModuleGenerator {
  final String name;

  ModuleGenerator(this.name);

  /// Generate all files for a module
  Map<String, String> generate() {
    final rc = ReCase(name);

    return {
      'lib/src/modules/$name/${name}_module.dart': _moduleFile(rc),
      'lib/src/modules/$name/controllers/${name}_controller.dart':
          _controllerFile(rc),
      'lib/src/modules/$name/services/${name}_service.dart': _serviceFile(rc),
      'lib/src/modules/$name/repositories/${name}_repository.dart':
          _repositoryFile(rc),
    };
  }

  String _moduleFile(ReCase rc) => '''
import 'package:neutronx/neutronx.dart';
import 'controllers/${name}_controller.dart';
import 'services/${name}_service.dart';
import 'repositories/${name}_repository.dart';
// [CONTROLLER_IMPORTS]

/// ${rc.titleCase} module
class ${rc.pascalCase}Module extends NeutronModule {
  @override
  String get name => '${rc.paramCase}';

  @override
  Future<void> register(ModuleContext context) async {
    // Register dependencies
    context.container.registerLazySingleton<${rc.pascalCase}Repository>(
      (c) => ${rc.pascalCase}Repository(),
    );
    
    context.container.registerLazySingleton<${rc.pascalCase}Service>(
      (c) => ${rc.pascalCase}Service(c.get<${rc.pascalCase}Repository>()),
    );

    // Register routes
    final service = context.container.get<${rc.pascalCase}Service>();
    ${rc.pascalCase}Controller(service).register(context.router);
    // [CONTROLLER_REGISTRATIONS]
  }

  @override
  Future<void> onInit() async {
    print('${rc.titleCase}Module: Initializing...');
  }

  @override
  Future<void> onReady() async {
    print('${rc.titleCase}Module: Ready');
  }
}
''';

  String _controllerFile(ReCase rc) => '''
import 'package:neutronx/neutronx.dart';
import '../services/${name}_service.dart';

class ${rc.pascalCase}Controller {
  final ${rc.pascalCase}Service _service;

  ${rc.pascalCase}Controller(this._service);

  void register(Router router) {
    router.get('/', _getAll);
    router.get('/:id', _getById);
    router.post('/', _create);
    router.put('/:id', _update);
    router.delete('/:id', _delete);
  }

  Future<Response> _getAll(Request req) async {
    final items = await _service.getAll();
    return Response.json(items);
  }

  Future<Response> _getById(Request req) async {
    final id = req.params['id']!;
    final item = await _service.getById(id);

    if (item == null) {
      return Response.notFound('${rc.titleCase} not found');
    }

    return Response.json(item);
  }

  Future<Response> _create(Request req) async {
    final data = await req.json();
    final item = await _service.create(data);
    return Response.json(item, statusCode: 201);
  }

  Future<Response> _update(Request req) async {
    final id = req.params['id']!;
    final data = await req.json();
    final item = await _service.update(id, data);

    if (item == null) {
      return Response.notFound('${rc.titleCase} not found');
    }

    return Response.json(item);
  }

  Future<Response> _delete(Request req) async {
    final id = req.params['id']!;
    final success = await _service.delete(id);

    if (!success) {
      return Response.notFound('${rc.titleCase} not found');
    }

    return Response.empty();
  }
}
''';

  String _serviceFile(ReCase rc) => '''
import '../repositories/${name}_repository.dart';

/// Service for ${rc.titleCase} business logic
class ${rc.pascalCase}Service {
  final ${rc.pascalCase}Repository _repository;

  ${rc.pascalCase}Service(this._repository);

  Future<List<Map<String, dynamic>>> getAll() async {
    return _repository.findAll();
  }

  Future<Map<String, dynamic>?> getById(String id) async {
    return _repository.findById(id);
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    // Add business logic here (validation, etc.)
    return _repository.create(data);
  }

  Future<Map<String, dynamic>?> update(String id, Map<String, dynamic> data) async {
    // Add business logic here
    return _repository.update(id, data);
  }

  Future<bool> delete(String id) async {
    return _repository.delete(id);
  }
}
''';

  String _repositoryFile(ReCase rc) => '''
/// Repository for ${rc.titleCase} data access
class ${rc.pascalCase}Repository {
  // In-memory storage (replace with database)
  final Map<String, Map<String, dynamic>> _storage = {};
  int _idCounter = 1;

  Future<List<Map<String, dynamic>>> findAll() async {
    return _storage.values.toList();
  }

  Future<Map<String, dynamic>?> findById(String id) async {
    return _storage[id];
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
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
    if (!_storage.containsKey(id)) {
      return null;
    }
    
    final item = {
      ..._storage[id]!,
      ...data,
      'id': id, // Ensure ID doesn't change
      'updatedAt': DateTime.now().toIso8601String(),
    };
    _storage[id] = item;
    return item;
  }

  Future<bool> delete(String id) async {
    if (!_storage.containsKey(id)) {
      return false;
    }
    _storage.remove(id);
    return true;
  }
}
''';
}
