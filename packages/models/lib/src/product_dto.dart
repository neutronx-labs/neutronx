/// Product Data Transfer Object
///
/// Example of a shared model for e-commerce functionality
class ProductDto {
  final String id;
  final String name;
  final String description;
  final double price;
  final int stock;

  ProductDto({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
  });

  factory ProductDto.fromJson(Map<String, dynamic> json) {
    return ProductDto(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      stock: json['stock'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
    };
  }

  @override
  String toString() => 'ProductDto(id: $id, name: $name, price: \$$price)';
}
