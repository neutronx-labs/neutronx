import 'package:args/args.dart';

/// Base class for all CLI commands
abstract class Command {
  /// The name of the command
  String get name;

  /// Description of what the command does
  String get description;

  /// Argument parser for this command
  ArgParser get argParser;

  /// Run the command with the given arguments
  Future<void> run(List<String> arguments);

  /// Print usage information for this command
  void printUsage() {
    print('$description\n');
    print('Usage: neutron $name [options]\n');
    print('Options:');
    print(argParser.usage);
  }
}
