/// User Data Transfer Object
///
/// This DTO is shared between the backend and Flutter frontend,
/// ensuring compile-time safety and type consistency.
class UserDto {
  final String id;
  final String name;
  final String email;
  final DateTime createdAt;

  UserDto({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
  });

  /// Creates a UserDto from JSON
  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Converts this UserDto to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() => 'UserDto(id: $id, name: $name, email: $email)';
}
