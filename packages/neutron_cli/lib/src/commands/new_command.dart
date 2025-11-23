import 'dart:io';
import 'package:args/args.dart';
import 'package:path/path.dart' as path;
import 'command.dart';
import '../cli_exception.dart';
import '../templates/project_template.dart';

/// Command to create a new NeutronX project
class NewCommand extends Command {
  @override
  String get name => 'new';

  @override
  String get description => 'Create a new NeutronX project';

  late final ArgParser _argParser;

  NewCommand() {
    _argParser = ArgParser()
      ..addFlag(
        'help',
        abbr: 'h',
        negatable: false,
        help: 'Print usage information',
      )
      ..addFlag(
        'monorepo',
        abbr: 'm',
        negatable: false,
        help: 'Create a monorepo structure with apps/ and packages/',
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
      throw CliException('Project name is required\nUsage: neutron new <project-name>');
    }

    final projectName = results.rest[0];
    final isMonorepo = results['monorepo'] as bool;

    // Validate project name
    if (!_isValidProjectName(projectName)) {
      throw CliException(
        'Invalid project name: $projectName\n'
        'Project names must be lowercase and use underscores (snake_case)',
      );
    }

    final projectDir = Directory(projectName);

    // Check if directory already exists
    if (await projectDir.exists()) {
      throw CliException('Directory "$projectName" already exists');
    }

    print('Creating NeutronX project: $projectName');
    print('');

    if (isMonorepo) {
      await _createMonorepoProject(projectName);
    } else {
      await _createStandardProject(projectName);
    }

    print('');
    print('✓ Project created successfully!');
    print('');
    print('Next steps:');
    print('  cd $projectName');
    print('  dart pub get');
    print('  neutron dev');
    print('');
    
    // Check if NEUTRONX_ROOT is set
    final neutronxRoot = Platform.environment['NEUTRONX_ROOT'];
    if (neutronxRoot == null || neutronxRoot.isEmpty) {
      print('⚠️  Note: NEUTRONX_ROOT environment variable not set');
      print('   For SDK-style usage, set it to your NeutronX directory:');
      print('   export NEUTRONX_ROOT=/path/to/neutronx');
      print('');
      print('   Or see docs/SDK_SETUP.md for complete setup guide');
      print('');
    }
  }

  bool _isValidProjectName(String name) {
    final pattern = RegExp(r'^[a-z][a-z0-9_]*$');
    return pattern.hasMatch(name);
  }

  Future<void> _createStandardProject(String projectName) async {
    final template = ProjectTemplate(projectName);

    print('Creating directories...');
    await _createDirectories(projectName, [
      'lib/src/core',
      'lib/src/modules',
      'lib/src/middleware',
      'lib/src/repositories',
      'lib/src/services',
      'test',
    ]);

    print('Generating files...');
    await _writeFile('$projectName/pubspec.yaml', template.pubspecYaml);
    await _writeFile('$projectName/analysis_options.yaml', template.analysisOptions);
    await _writeFile('$projectName/.gitignore', template.gitignore);
    await _writeFile('$projectName/README.md', template.readme);
    await _writeFile('$projectName/lib/${projectName}.dart', template.mainLibrary);
    await _writeFile('$projectName/bin/server.dart', template.serverMain);

    print('✓ Created standard project structure');
  }

  Future<void> _createMonorepoProject(String projectName) async {
    final template = ProjectTemplate(projectName);

    print('Creating monorepo structure...');
    await _createDirectories(projectName, [
      'apps/backend/lib/src/modules',
      'apps/backend/lib/src/middleware',
      'apps/backend/test',
      'apps/mobile/lib',
      'packages/models/lib/src',
    ]);

    print('Generating files...');

    // Root files
    await _writeFile('$projectName/README.md', template.monorepoReadme);
    await _writeFile('$projectName/.gitignore', template.gitignore);

    // Backend app
    await _writeFile('$projectName/apps/backend/pubspec.yaml', template.backendPubspec);
    await _writeFile('$projectName/apps/backend/analysis_options.yaml', template.analysisOptions);
    await _writeFile('$projectName/apps/backend/bin/server.dart', template.serverMain);
    await _writeFile('$projectName/apps/backend/lib/backend.dart', template.mainLibrary);

    // Mobile app placeholder
    await _writeFile('$projectName/apps/mobile/pubspec.yaml', template.mobilePubspec);
    await _writeFile('$projectName/apps/mobile/lib/main.dart', template.mobileMain);

    // Shared models package
    await _writeFile('$projectName/packages/models/pubspec.yaml', template.modelsPubspec);
    await _writeFile('$projectName/packages/models/lib/models.dart', template.modelsLibrary);

    print('✓ Created monorepo structure');
  }

  Future<void> _createDirectories(String projectName, List<String> dirs) async {
    for (final dir in dirs) {
      await Directory(path.join(projectName, dir)).create(recursive: true);
    }
  }

  Future<void> _writeFile(String filePath, String content) async {
    final file = File(filePath);
    await file.create(recursive: true);
    await file.writeAsString(content);
  }
}
