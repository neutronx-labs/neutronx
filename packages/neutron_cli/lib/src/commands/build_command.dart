import 'dart:io';
import 'package:args/args.dart';
import 'command.dart';
import '../cli_exception.dart';

/// Command to build project for production
class BuildCommand extends Command {
  @override
  String get name => 'build';

  @override
  String get description => 'Build project for production';

  late final ArgParser _argParser;

  BuildCommand() {
    _argParser = ArgParser()
      ..addFlag(
        'help',
        abbr: 'h',
        negatable: false,
        help: 'Print usage information',
      )
      ..addOption(
        'entry',
        abbr: 'e',
        defaultsTo: 'bin/server.dart',
        help: 'Entry point file',
      )
      ..addOption(
        'output',
        abbr: 'o',
        defaultsTo: 'build/server',
        help: 'Output executable path',
      )
      ..addMultiOption(
        'define',
        abbr: 'D',
        help: 'Compile-time dart defines (key=value)',
      )
      ..addOption(
        'target-arch',
        help: 'Target architecture (e.g., x64, arm64)',
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

    final entry = results['entry'] as String;
    final output = results['output'] as String;
    final defines = (results['define'] as List<String>?) ?? [];
    final targetArch = results['target-arch'] as String?;

    // Check if entry file exists
    final entryFile = File(entry);
    if (!await entryFile.exists()) {
      throw CliException('Entry file not found: $entry');
    }

    // Ensure output directory exists (dart compile won't create it)
    final outputFile = File(output);
    await outputFile.parent.create(recursive: true);

    print('Building project for production...');
    print('Entry: $entry');
    print('Output: $output');
    print('');

    // Compile to native executable
    final process = await Process.start(
      'dart',
      [
        'compile',
        'exe',
        entry,
        '-o',
        output,
        if (targetArch != null) '-a',
        if (targetArch != null) targetArch,
        ...defines.map((d) => '-D$d'),
      ],
    );

    // Forward output
    process.stdout.listen((data) {
      stdout.add(data);
    });

    process.stderr.listen((data) {
      stderr.add(data);
    });

    final exitCode = await process.exitCode;

    if (exitCode == 0) {
      print('');
      print('✓ Build successful!');
      print('');
      print('Run your server:');
      print('  ./$output');
      print('');
    } else {
      throw CliException('Build failed with exit code $exitCode',
          exitCode: exitCode);
    }
  }
}
