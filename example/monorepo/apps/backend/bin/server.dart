import 'package:neutronx/neutronx.dart';
import 'package:models/models.dart';

void main() async {
  final app = NeutronApp();
  final router = Router();

  // Example: Using shared DTOs
  router.get('/users/:id', (req) async {
    final id = req.params['id'];

    // Create a UserDto that's shared with Flutter
    final user = UserDto(
      id: id!,
      name: 'John Doe',
      email: 'john@example.com',
      createdAt: DateTime.now(),
    );

    return Response.json(user.toJson());
  });

  router.get('/products', (req) async {
    // Create ProductDtos that are shared with Flutter
    final products = [
      ProductDto(
        id: '1',
        name: 'MacBook Pro',
        description: 'Apple MacBook Pro 16-inch',
        price: 2499.99,
        stock: 10,
      ),
      ProductDto(
        id: '2',
        name: 'iPhone 15 Pro',
        description: 'Latest iPhone with titanium design',
        price: 999.99,
        stock: 25,
      ),
    ];

    return Response.json({
      'products': products.map((p) => p.toJson()).toList(),
    });
  });

  app.use(router);
  await app.listen(port: 3000);
  print('🚀 Backend running on http://localhost:3000');
  print('📦 Using shared models from packages/models');
}
