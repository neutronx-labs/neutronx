/// Exception thrown when a circular dependency is detected in the DI container
///
/// NeutronX enforces acyclic dependency graphs to prevent unpredictable
/// startup states.
///
/// Example cycle: A → B → C → A
class CircularDependencyError extends Error {
  final String message;
  final List<Type> dependencyChain;

  CircularDependencyError(this.message, this.dependencyChain);

  @override
  String toString() {
    final chain = dependencyChain.map((t) => t.toString()).join(' → ');
    return 'CircularDependencyError: $message\nDependency chain: $chain';
  }
}
