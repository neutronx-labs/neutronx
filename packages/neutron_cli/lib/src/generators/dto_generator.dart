import 'package:recase/recase.dart';

/// Generator for DTOs
class DtoGenerator {
  final String name;

  DtoGenerator(this.name);

  String generate() {
    final rc = ReCase(name);

    return '''
/// Data Transfer Object for ${rc.titleCase}
class ${rc.pascalCase}Dto {
  final String id;
  final String name;
  final DateTime createdAt;

  ${rc.pascalCase}Dto({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  /// Create from JSON
  factory ${rc.pascalCase}Dto.fromJson(Map<String, dynamic> json) {
    return ${rc.pascalCase}Dto(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create a copy with modified fields
  ${rc.pascalCase}Dto copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
  }) {
    return ${rc.pascalCase}Dto(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ${rc.pascalCase}Dto &&
        other.id == id &&
        other.name == name &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(id, name, createdAt);

  @override
  String toString() {
    return '${rc.pascalCase}Dto(id: \$id, name: \$name, createdAt: \$createdAt)';
  }
}
''';
  }
}
