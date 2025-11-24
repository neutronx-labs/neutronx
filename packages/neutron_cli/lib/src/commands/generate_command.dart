import 'dart:io';
import 'package:args/args.dart';
import 'package:recase/recase.dart';
import 'command.dart';
import '../cli_exception.dart';
import '../generators/module_generator.dart';
import '../generators/dto_generator.dart';
import '../generators/service_generator.dart';
import '../generators/repository_generator.dart';

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
    final generator = ServiceGenerator(name);
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

  Future<void> _writeFile(String filePath, String content) async {
    final file = File(filePath);
    await file.create(recursive: true);
    await file.writeAsString(content);
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

  String _emptyModuleRegistryTemplate() => '''
import 'package:neutronx/neutronx.dart';

// [MODULE_IMPORTS]

// Re-export modules
// [MODULE_EXPORTS]

List<NeutronModule> buildModules() => [
  // [MODULE_REGISTRATIONS]
];
''';
}
