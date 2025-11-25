import 'dart:io';
import 'package:args/args.dart';
import 'package:recase/recase.dart';
import 'command.dart';
import '../cli_exception.dart';
import '../generators/module_generator.dart';
import '../generators/dto_generator.dart';
import '../generators/service_generator.dart';
import '../generators/repository_generator.dart';
import '../generators/controller_generator.dart';

/// Command to generate code (modules, DTOs, services, etc.)
class GenerateCommand extends Command {
  @override
  String get name => 'generate';

  @override
  String get description => 'Generate code (module, dto, service, repository)';

  late final ArgParser _argParser;

  GenerateCommand() {
    _argParser = ArgParser()
      ..addFlag(
        'help',
        abbr: 'h',
        negatable: false,
        help: 'Print usage information',
      )
      ..addOption(
        'module',
        help: 'Target module for controller generation (defaults to name)',
      )
      ..addFlag(
        'bare',
        negatable: false,
        help: 'Generate controller outside a module (manual wiring required)',
      );
  }

  @override
  ArgParser get argParser => _argParser;

  @override
  Future<void> run(List<String> arguments) async {
    final results = _argParser.parse(arguments);

    if (results['help'] as bool) {
      printUsage();
      return;
    }

    if (results.rest.isEmpty) {
      throw CliException(
        'Type is required\nUsage: neutron generate <type> <name>\n\n'
        'Available types:\n'
        '  module      Generate a NeutronX module\n'
        '  controller  Generate a controller (module-scoped by default)\n'
        '  dto         Generate a Data Transfer Object\n'
        '  service     Generate a service class\n'
        '  repository  Generate a repository class',
      );
    }

    if (results.rest.length < 2) {
      throw CliException(
          'Name is required\nUsage: neutron generate <type> <name>');
    }

    final type = results.rest[0];
    final name = results.rest[1];

    // Validate name
    if (!_isValidName(name)) {
      throw CliException(
        'Invalid name: $name\n'
        'Names must be lowercase and use underscores (snake_case)',
      );
    }

    switch (type) {
      case 'module':
      case 'm':
        await _generateModule(name);
        break;
      case 'dto':
      case 'd':
        await _generateDto(name);
        break;
      case 'controller':
      case 'c':
        await _generateController(name, results);
        break;
      case 'service':
      case 's':
        await _generateService(name);
        break;
      case 'repository':
      case 'r':
        await _generateRepository(name);
        break;
      default:
        throw CliException(
          'Unknown type: $type\n\n'
          'Available types: module, dto, service, repository',
        );
    }
  }

  bool _isValidName(String name) {
    final pattern = RegExp(r'^[a-z][a-z0-9_]*$');
    return pattern.hasMatch(name);
  }

  Future<void> _generateModule(String name) async {
    final generator = ModuleGenerator(name);
    final files = generator.generate();

    print('Generating module: $name');
    print('');

    for (final entry in files.entries) {
      await _writeFile(entry.key, entry.value);
      print('  ✓ ${entry.key}');
    }

    await _updateModuleRegistry(name);

    print('');
    print('Module generated successfully!');
    print('');
    print(
        'Module registry updated: buildModules() now includes ${name.pascalCase}Module.');
  }

  Future<void> _generateDto(String name) async {
    final generator = DtoGenerator(name);
    final content = generator.generate();

    print('Generating DTO: $name');
    print('');

    final filePath = 'lib/src/dtos/${name}_dto.dart';
    await _writeFile(filePath, content);
    print('  ✓ $filePath');

    print('');
    print('DTO generated successfully!');
  }

  Future<void> _generateService(String name) async {
    final repoPath = 'lib/src/repositories/${name}_repository.dart';
    final repoFile = File(repoPath);
    var useRepository = await repoFile.exists();

    if (!useRepository) {
      final shouldCreateRepo = await _promptYesNo(
        'No repository found for "$name". Create $repoPath now? (Y/n): ',
        defaultYes: true,
      );
      if (shouldCreateRepo) {
        final repoGenerator = RepositoryGenerator(name);
        await _writeFile(repoPath, repoGenerator.generate());
        print('  ✓ $repoPath');
        useRepository = true;
      } else {
        print(
            '  ⚠️ Skipped repository. Generating service without repository dependency.');
      }
    }

    final generator = ServiceGenerator(name, useRepository: useRepository);
    final content = generator.generate();

    print('Generating service: $name');
    print('');

    final filePath = 'lib/src/services/${name}_service.dart';
    await _writeFile(filePath, content);
    print('  ✓ $filePath');

    print('');
    print('Service generated successfully!');
  }

  Future<void> _generateRepository(String name) async {
    final generator = RepositoryGenerator(name);
    final content = generator.generate();

    print('Generating repository: $name');
    print('');

    final filePath = 'lib/src/repositories/${name}_repository.dart';
    await _writeFile(filePath, content);
    print('  ✓ $filePath');

    print('');
    print('Repository generated successfully!');
  }

  Future<void> _generateController(String name, ArgResults results) async {
    final isBare = results['bare'] as bool;
    final moduleOption = results['module'] as String?;
    final targetModule = isBare ? null : (moduleOption ?? name);
    final generator = ControllerGenerator(
      name,
      moduleName: targetModule,
      bare: isBare,
    );

    final filePath = isBare
        ? 'lib/src/controllers/${name}_controller.dart'
        : 'lib/src/modules/$targetModule/controllers/${name}_controller.dart';

    print('Generating controller: $name');
    if (targetModule != null) {
      print('Target module: $targetModule');
    } else {
      print('Mode: bare (manual wiring)');
    }
    print('');

    if (!isBare) {
      final moduleFile =
          File('lib/src/modules/$targetModule/${targetModule}_module.dart');
      if (!moduleFile.existsSync()) {
        throw CliException(
          'Module "$targetModule" not found at ${moduleFile.path}\n'
          'Create the module first or use --bare to generate a standalone controller.',
        );
      }
    }

    await _writeFile(filePath, generator.generate());
    print('  ✓ $filePath');

    if (!isBare && targetModule != null) {
      final moduleFilePath =
          'lib/src/modules/$targetModule/${targetModule}_module.dart';
      final updated = await _updateModuleForController(
        moduleFilePath,
        controllerName: name,
      );
      if (updated) {
        print('  ✓ Updated $moduleFilePath');
      } else {
        print(
          '  ⚠️ Could not auto-update $moduleFilePath. Please import and register the controller manually.',
        );
      }
    } else if (isBare) {
      final updated = await _updateControllersRegistry(name);
      if (updated) {
        print('  ✓ Updated lib/src/controllers/controllers.dart');
      } else {
        print(
          '  ⚠️ Could not auto-update controllers registry. Please wire the controller manually.',
        );
      }
    }

    print('');
    print('Controller generated successfully!');
    if (isBare) {
      print('Remember to wire the controller into a router manually.');
    }
  }

  Future<void> _writeFile(String filePath, String content) async {
    final file = File(filePath);
    await file.create(recursive: true);
    await file.writeAsString(content);
  }

  Future<bool> _promptYesNo(String message, {bool defaultYes = true}) async {
    stdout.write(message);
    final input = stdin.readLineSync()?.trim().toLowerCase();
    if (input == null || input.isEmpty) return defaultYes;
    if (input == 'y' || input == 'yes') return true;
    if (input == 'n' || input == 'no') return false;
    return defaultYes;
  }

  Future<void> _updateModuleRegistry(String name) async {
    final rc = ReCase(name);
    const markerImports = '// [MODULE_IMPORTS]';
    const markerExports = '// [MODULE_EXPORTS]';
    const markerRegistrations = '// [MODULE_REGISTRATIONS]';
    const registryPath = 'lib/src/modules/modules.dart';
    final registryFile = File(registryPath);

    if (!await registryFile.exists()) {
      await registryFile.create(recursive: true);
      await registryFile.writeAsString(_emptyModuleRegistryTemplate());
    }

    var content = await registryFile.readAsString();

    // Ensure markers exist
    if (!content.contains(markerImports) ||
        !content.contains(markerExports) ||
        !content.contains(markerRegistrations)) {
      content = _emptyModuleRegistryTemplate();
    }

    final importLine = "import '${rc.snakeCase}/${rc.snakeCase}_module.dart';";
    final exportLine = "export '${rc.snakeCase}/${rc.snakeCase}_module.dart';";
    final registrationLine = '  ${rc.pascalCase}Module(),';

    if (!content.contains(importLine)) {
      content =
          content.replaceFirst(markerImports, '$importLine\n$markerImports');
    }

    if (!content.contains(exportLine)) {
      content =
          content.replaceFirst(markerExports, '$exportLine\n$markerExports');
    }

    if (!content.contains(registrationLine)) {
      content = content.replaceFirst(
        markerRegistrations,
        '$registrationLine\n  $markerRegistrations',
      );
    }

    await registryFile.writeAsString(content);
  }

  Future<bool> _updateModuleForController(
    String moduleFilePath, {
    required String controllerName,
  }) async {
    const markerImports = '// [CONTROLLER_IMPORTS]';
    const markerRegistrations = '// [CONTROLLER_REGISTRATIONS]';

    final file = File(moduleFilePath);
    if (!await file.exists()) {
      return false;
    }

    var content = await file.readAsString();

    if (!content.contains(markerImports) ||
        !content.contains(markerRegistrations)) {
      return false;
    }

    final rc = ReCase(controllerName);
    final importLine = "import 'controllers/${rc.snakeCase}_controller.dart';";
    final registrationLine =
        '    ${rc.pascalCase}Controller().register(ctx.router);';

    if (!content.contains(importLine)) {
      content =
          content.replaceFirst(markerImports, '$importLine\n$markerImports');
    }

    if (!content.contains(registrationLine)) {
      content = content.replaceFirst(
        markerRegistrations,
        '$registrationLine\n    $markerRegistrations',
      );
    }

    await file.writeAsString(content);
    return true;
  }

  Future<bool> _updateControllersRegistry(String controllerName) async {
    const markerImports = '// [CONTROLLER_IMPORTS]';
    const markerRegistrations = '// [CONTROLLER_REGISTRATIONS]';
    const registryPath = 'lib/src/controllers/controllers.dart';
    final rc = ReCase(controllerName);

    final file = File(registryPath);
    if (!await file.exists()) {
      await file.create(recursive: true);
      await file.writeAsString(_emptyControllersRegistryTemplate());
    }

    var content = await file.readAsString();
    if (!content.contains(markerImports) ||
        !content.contains(markerRegistrations)) {
      return false;
    }

    final importLine = "import '${rc.snakeCase}_controller.dart';";
    final registrationBlock = '''
  final ${rc.camelCase}Router = Router();
  ${rc.pascalCase}Controller().register(${rc.camelCase}Router);
  router.mount('/${rc.paramCase}', ${rc.camelCase}Router);
''';

    if (!content.contains(importLine)) {
      content =
          content.replaceFirst(markerImports, '$importLine\n$markerImports');
    }

    if (!content.contains(registrationBlock.trim())) {
      content = content.replaceFirst(
        markerRegistrations,
        '$registrationBlock  $markerRegistrations',
      );
    }

    await file.writeAsString(content);
    return true;
  }

  String _emptyModuleRegistryTemplate() => '''
import 'package:neutronx/neutronx.dart';

// [MODULE_IMPORTS]

// Re-export modules
// [MODULE_EXPORTS]

List<NeutronModule> buildModules() => [
  // [MODULE_REGISTRATIONS]
];
''';

  String _emptyControllersRegistryTemplate() => '''
import 'package:neutronx/neutronx.dart';

// [CONTROLLER_IMPORTS]

void registerControllers(Router router) {
  // [CONTROLLER_REGISTRATIONS]
}
''';
}
