/// Exception thrown by CLI commands
class CliException implements Exception {
  final String message;
  final int exitCode;

  CliException(this.message, {this.exitCode = 1});

  @override
  String toString() => message;
}
