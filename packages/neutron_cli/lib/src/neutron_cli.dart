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

Run "neutron <command> --help" for more information about a command.

Examples:
  neutron new my_backend       Create a new project called "my_backend"
  neutron generate module users    Generate a users module
  neutron generate dto product     Generate a product DTO
  neutron dev --port 3000      Start dev server on port 3000
  neutron build                Build for production
''');
  }

  void _printVersion() {
    print('NeutronX CLI version 0.1.0');
  }
}
