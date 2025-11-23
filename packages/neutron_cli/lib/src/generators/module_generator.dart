import 'package:recase/recase.dart';

/// Generator for NeutronX modules
class ModuleGenerator {
  final String name;

  ModuleGenerator(this.name);

  /// Generate all files for a module
  Map<String, String> generate() {
    final rc = ReCase(name);

    return {
      'lib/src/modules/${name}_module.dart': _moduleFile(rc),
      'lib/src/services/${name}_service.dart': _serviceFile(rc),
      'lib/src/repositories/${name}_repository.dart': _repositoryFile(rc),
    };
  }

  String _moduleFile(ReCase rc) => '''
import 'package:neutronx/neutronx.dart';
import '../services/${name}_service.dart';
import '../repositories/${name}_repository.dart';

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
    final router = context.router;

    // GET /${rc.paramCase}
    router.get('/', (req) async {
      final items = await service.getAll();
      return Response.json(items);
    });

    // GET /${rc.paramCase}/:id
    router.get('/:id', (req) async {
      final id = req.params['id']!;
      final item = await service.getById(id);
      
      if (item == null) {
        return Response.notFound('${rc.titleCase} not found');
      }
      
      return Response.json(item);
    });

    // POST /${rc.paramCase}
    router.post('/', (req) async {
      final data = await req.json();
      final item = await service.create(data);
      return Response.json(item, statusCode: 201);
    });

    // PUT /${rc.paramCase}/:id
    router.put('/:id', (req) async {
      final id = req.params['id']!;
      final data = await req.json();
      final item = await service.update(id, data);
      
      if (item == null) {
        return Response.notFound('${rc.titleCase} not found');
      }
      
      return Response.json(item);
    });

    // DELETE /${rc.paramCase}/:id
    router.delete('/:id', (req) async {
      final id = req.params['id']!;
      final success = await service.delete(id);
      
      if (!success) {
        return Response.notFound('${rc.titleCase} not found');
      }
      
      return Response.empty();
    });
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
