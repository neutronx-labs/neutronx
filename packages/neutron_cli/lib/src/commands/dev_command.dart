import 'dart:io';
import 'package:args/args.dart';
import 'command.dart';
import '../cli_exception.dart';

/// Command to start development server with hot reload
class DevCommand extends Command {
  @override
  String get name => 'dev';

  @override
  String get description => 'Start development server with hot reload';

  late final ArgParser _argParser;

  DevCommand() {
    _argParser = ArgParser()
      ..addFlag(
        'help',
        abbr: 'h',
        negatable: false,
        help: 'Print usage information',
      )
      ..addOption(
        'port',
        abbr: 'p',
        defaultsTo: '3000',
        help: 'Port to run the server on',
      )
      ..addOption(
        'host',
        defaultsTo: 'localhost',
        help: 'Host to bind the server to',
      )
      ..addOption(
        'entry',
        abbr: 'e',
        defaultsTo: 'bin/server.dart',
        help: 'Entry point file',
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

    final port = results['port'] as String;
    final host = results['host'] as String;
    final entry = results['entry'] as String;

    // Check if entry file exists
    final entryFile = File(entry);
    if (!await entryFile.exists()) {
      throw CliException('Entry file not found: $entry');
    }

    print('Starting development server...');
    print('Entry: $entry');
    print('Host: $host');
    print('Port: $port');
    print('');
    print('Watching for file changes...');
    print('Press Ctrl+C to stop');
    print('');

    // Run with dart run and enable VM service for hot reload
    final process = await Process.start(
      'dart',
      [
        'run',
        '--enable-vm-service',
        '--observe',
        entry,
      ],
      environment: {
        'HOST': host,
        'PORT': port,
      },
    );

    // Forward output
    process.stdout.listen((data) {
      stdout.add(data);
    });

    process.stderr.listen((data) {
      stderr.add(data);
    });

    // Wait for process to exit
    final exitCode = await process.exitCode;
    exit(exitCode);
  }
}
