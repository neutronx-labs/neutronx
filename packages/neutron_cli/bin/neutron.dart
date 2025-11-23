#!/usr/bin/env dart

import 'dart:io';
import 'package:neutron_cli/neutron_cli.dart';

void main(List<String> arguments) async {
  final cli = NeutronCli();

  try {
    await cli.run(arguments);
  } on CliException catch (e) {
    stderr.writeln('Error: ${e.message}');
    exit(e.exitCode);
  } catch (e) {
    stderr.writeln('Unexpected error: $e');
    exit(1);
  }
}
