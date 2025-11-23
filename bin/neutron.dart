#!/usr/bin/env dart

/// Convenience script to run the NeutronX CLI from the root directory.
/// This delegates to the actual CLI implementation in packages/neutron_cli.
///
/// Usage:
///   dart run bin/neutron.dart <command> [arguments]
///   
/// Or make it executable:
///   chmod +x bin/neutron.dart
///   ./bin/neutron.dart <command> [arguments]

import 'dart:io';

void main(List<String> arguments) async {
  // Path to the actual CLI implementation
  final cliPath = 'packages/neutron_cli/bin/neutron.dart';
  final cliFile = File(cliPath);

  // Check if CLI exists
  if (!await cliFile.exists()) {
    stderr.writeln('Error: NeutronX CLI not found at $cliPath');
    stderr.writeln('Make sure you are running from the NeutronX root directory.');
    exit(1);
  }

  // Run the actual CLI with all arguments
  final result = await Process.run(
    'dart',
    ['run', cliPath, ...arguments],
    runInShell: true,
  );

  // Forward output
  stdout.write(result.stdout);
  stderr.write(result.stderr);

  // Exit with same code
  exit(result.exitCode);
}
