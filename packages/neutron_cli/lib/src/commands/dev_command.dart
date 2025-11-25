import 'dart:async';
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
      ..addMultiOption(
        'define',
        abbr: 'D',
        help: 'Compile-time dart defines (key=value)',
      )
      ..addOption(
        'entry',
        abbr: 'e',
        defaultsTo: 'bin/server.dart',
        help: 'Entry point file',
      )
      ..addFlag(
        'watch',
        defaultsTo: true,
        help: 'Restart the server when files change',
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
    final defines = (results['define'] as List<String>?) ?? [];
    final watch = results['watch'] as bool;

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
    if (watch) {
      print('Watching for file changes...');
    }
    print('Press Ctrl+C to stop');
    print('');

    Future<Process> start() async {
      final args = [
        'run',
        '--enable-vm-service',
        '--observe',
        '--no-pause-isolates-on-start',
        '--no-pause-isolates-on-exit',
        '--no-pause-isolates-on-unhandled-exceptions',
        ...defines.map((d) => '-D$d'),
        entry,
      ];
      final process = await Process.start(
        'dart',
        args,
        environment: {
          'HOST': host,
          'PORT': port,
        },
        mode: ProcessStartMode.inheritStdio,
      );
      return process;
    }

    Process current = await start();

    final subs = <StreamSubscription<FileSystemEvent>>[];
    final signalSubs = <StreamSubscription<ProcessSignal>>[];

    var stopping = false;

    Future<void> stopAndExit([int code = 0]) async {
      if (stopping) return;
      stopping = true;
      for (final sub in subs) {
        await sub.cancel();
      }
      current.kill(ProcessSignal.sigterm);
      await current.exitCode;
      for (final sig in signalSubs) {
        await sig.cancel();
      }
      exit(code);
    }

    signalSubs.add(ProcessSignal.sigint.watch().listen((_) async {
      await stopAndExit(130); // 128 + SIGINT
    }));
    signalSubs.add(ProcessSignal.sigterm.watch().listen((_) async {
      await stopAndExit(143); // 128 + SIGTERM
    }));
    if (watch) {
      final dirsToWatch = ['lib', 'bin'];
      final watchers = dirsToWatch
          .map((d) => Directory(d))
          .where((d) => d.existsSync())
          .map((d) => d.watch(recursive: true));

      DateTime lastChange = DateTime.now();
      void handleEvent(FileSystemEvent event) async {
        final now = DateTime.now();
        // Debounce rapid events
        if (now.difference(lastChange) < const Duration(milliseconds: 200)) {
          return;
        }
        lastChange = now;

        print('↻ Change detected in ${event.path}. Restarting...');
        current.kill(ProcessSignal.sigterm);
        await current.exitCode;
        current = await start();
      }

      for (final watcher in watchers) {
        subs.add(watcher.listen(handleEvent));
      }
    }

    // Wait for current to exit (Ctrl+C)
    final exitCode = await current.exitCode;
    for (final sub in subs) {
      await sub.cancel();
    }
    for (final sig in signalSubs) {
      await sig.cancel();
    }
    exit(exitCode);
  }
}
