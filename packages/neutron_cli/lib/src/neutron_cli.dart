import 'dart:io';
import 'package:args/args.dart';
import 'commands/command.dart';
import 'commands/new_command.dart';
import 'commands/generate_command.dart';
import 'commands/dev_command.dart';
import 'commands/build_command.dart';
import 'cli_exception.dart';

/// Main CLI class that orchestrates all commands
class NeutronCli {
  final Map<String, Command> _commands = {};
  late final ArgParser _parser;

  NeutronCli() {
    _registerCommands();
    _setupParser();
  }

  void _registerCommands() {
    _commands['new'] = NewCommand();
    _commands['generate'] = GenerateCommand();
    _commands['dev'] = DevCommand();
    _commands['build'] = BuildCommand();
  }

  void _setupParser() {
    _parser = ArgParser()
      ..addFlag(
        'help',
        abbr: 'h',
        negatable: false,
        help: 'Print this usage information.',
      )
      ..addFlag(
        'version',
        abbr: 'v',
        negatable: false,
        help: 'Print the version of NeutronX CLI.',
      );
  }

  Future<void> run(List<String> arguments) async {
    try {
      final results = _parser.parse(arguments);

      if (results['help'] as bool) {
        _printUsage();
        return;
      }

      if (results['version'] as bool) {
        _printVersion();
        return;
      }

      if (results.rest.isEmpty) {
        _printUsage();
        throw CliException('No command specified', exitCode: 1);
      }

      final commandName = results.rest[0];
      
      // Handle 'pub' as a special pass-through command
      if (commandName == 'pub') {
        await _runPubCommand(results.rest.sublist(1));
        return;
      }
      
      final command = _commands[commandName];

      if (command == null) {
        _printUsage();
        throw CliException('Unknown command: $commandName', exitCode: 1);
      }

      final commandArgs = results.rest.sublist(1);
      await command.run(commandArgs);
    } on FormatException catch (e) {
      throw CliException(e.message, exitCode: 1);
    }
  }

  void _printUsage() {
    print('''
NeutronX CLI - Flutter-first Dart backend framework

Usage: neutron <command> [arguments]

Global options:
${_parser.usage}

Available commands:
  new <project-name>           Create a new NeutronX project
  generate <type> <name>       Generate code (module, dto, service, repository)
  dev [options]                Start development server with hot reload
  build [options]              Build project for production
  pub <command>                Run pub commands (supports 'sdk: neutronx' syntax)

Run "neutron <command> --help" for more information about a command.

Examples:
  neutron new my_backend       Create a new project called "my_backend"
  neutron generate module users    Generate a users module
  neutron generate dto product     Generate a product DTO
  neutron dev --port 3000      Start dev server on port 3000
  neutron build                Build for production
  neutron pub get              Run pub get (transforms sdk: neutronx)
''');
  }

  void _printVersion() {
    print('NeutronX CLI version 0.1.0');
  }

  /// Run pub commands with SDK transformation
  Future<void> _runPubCommand(List<String> args) async {
    const pubspecFile = 'pubspec.yaml';
    const backupFile = '.pubspec.yaml.neutron-backup';
    
    if (!File(pubspecFile).existsSync()) {
      print('Error: No pubspec.yaml found in current directory');
      throw CliException('pubspec.yaml not found', exitCode: 1);
    }

    // Check if NEUTRONX_ROOT is set
    final neutronxRoot = Platform.environment['NEUTRONX_ROOT'];
    if (neutronxRoot == null || neutronxRoot.isEmpty) {
      print('Error: NEUTRONX_ROOT environment variable not set');
      print('Please set it to your NeutronX installation path:');
      print('  export NEUTRONX_ROOT=/path/to/neutronx');
      throw CliException('NEUTRONX_ROOT not set', exitCode: 1);
    }

    File? backup;
    try {
      // Read original pubspec
      final pubspecContent = await File(pubspecFile).readAsString();
      
      // Check if it contains "sdk: neutronx"
      if (pubspecContent.contains('sdk: neutronx')) {
        // Create backup
        backup = File(backupFile);
        await backup.writeAsString(pubspecContent);
        
        // Transform sdk: neutronx to path: $NEUTRONX_ROOT
        final transformed = pubspecContent.replaceAll(
          RegExp(r'sdk:\s*neutronx'),
          'path: $neutronxRoot',
        );
        await File(pubspecFile).writeAsString(transformed);
        
        print('→ Transformed sdk: neutronx to path: $neutronxRoot');
      }

      // Run dart pub command
      final result = await Process.run(
        'dart',
        ['pub', ...args],
        runInShell: true,
      );

      stdout.write(result.stdout);
      stderr.write(result.stderr);

      if (result.exitCode != 0) {
        throw CliException('pub command failed', exitCode: result.exitCode);
      }
    } finally {
      // Restore original pubspec if we made a backup
      if (backup != null && await backup.exists()) {
        final originalContent = await backup.readAsString();
        await File(pubspecFile).writeAsString(originalContent);
        await backup.delete();
        print('→ Restored original pubspec.yaml');
      }
    }
  }
}
