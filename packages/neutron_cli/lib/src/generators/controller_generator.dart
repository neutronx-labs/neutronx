import 'package:recase/recase.dart';

/// Generator for standalone or module-scoped controllers
class ControllerGenerator {
  final String name;
  final String? moduleName;
  final bool bare;

  ControllerGenerator(
    this.name, {
    this.moduleName,
    this.bare = false,
  });

  String generate() {
    return bare ? _bareController() : _moduleScopedController();
  }

  String _moduleScopedController() {
    final rc = ReCase(name);
    final moduleLabel = moduleName ?? rc.paramCase;

    return '''
import 'package:neutronx/neutronx.dart';

/// Controller for $moduleLabel endpoints
class ${rc.pascalCase}Controller {
  void register(Router router) {
    router.get('/', _list);
    router.get('/:id', _getById);
    router.post('/', _create);
    router.put('/:id', _update);
    router.delete('/:id', _delete);
  }

  Future<Response> _list(Request req) async {
    // TODO: inject dependencies via constructor and implement logic
    return Response.json({'items': []});
  }

  Future<Response> _getById(Request req) async {
    final id = req.params['id']!;
    return Response.json({'id': id});
  }

  Future<Response> _create(Request req) async {
    final data = await req.json();
    return Response.json(data, statusCode: 201);
  }

  Future<Response> _update(Request req) async {
    final id = req.params['id']!;
    final data = await req.json();
    return Response.json({'id': id, ...data});
  }

  Future<Response> _delete(Request req) async {
    final id = req.params['id']!;
    return Response.json({'deleted': id});
  }
}
''';
  }

  String _bareController() {
    final rc = ReCase(name);
    return '''
import 'package:neutronx/neutronx.dart';

/// Standalone controller. Wire into a Router manually.
class ${rc.pascalCase}Controller {
  void register(Router router) {
    router.get('/', _hello);
  }

  Future<Response> _hello(Request req) async {
    return Response.json({'message': '${rc.titleCase} controller'});
  }
}
''';
  }
}
