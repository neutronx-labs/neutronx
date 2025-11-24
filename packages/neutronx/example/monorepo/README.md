# NeutronX Monorepo Example

This example demonstrates how to set up a monorepo with NeutronX backend and Flutter mobile app sharing the same DTOs.

## Structure

```
monorepo/
├── apps/
│   ├── backend/          # NeutronX backend server
│   │   ├── bin/
│   │   │   └── server.dart
│   │   └── pubspec.yaml
│   └── mobile/           # Flutter mobile application
│       ├── lib/
│       │   └── main.dart
│       └── pubspec.yaml
└── packages/
    └── models/           # Shared DTOs used by both backend and mobile
        ├── lib/
        │   ├── models.dart
        │   └── src/
        │       ├── user_dto.dart
        │       └── product_dto.dart
        └── pubspec.yaml
```

## Key Benefits

1. **Shared DTOs**: Both backend and mobile use the same data models
2. **Type Safety**: Compile-time verification of data structures
3. **Single Source of Truth**: Update models in one place
4. **Code Reuse**: Validation logic, serialization, etc.

## Setup

### Option 1: Using Melos (Recommended)

```bash
# Install melos
dart pub global activate melos

# Bootstrap all packages
melos bootstrap

# Run backend
melos run backend:start

# Run mobile (in another terminal)
melos run mobile:run
```

### Option 2: Manual Setup

```bash
# Install dependencies for each package
cd packages/models && dart pub get
cd ../../apps/backend && dart pub get
cd ../mobile && flutter pub get

# Run backend
cd apps/backend
dart run bin/server.dart

# Run mobile (in another terminal)
cd apps/mobile
flutter run
```

## Usage Example

### Backend (apps/backend/bin/server.dart)

```dart
import 'package:neutronx/neutronx.dart';
import 'package:models/models.dart';

void main() async {
  final app = NeutronApp();
  final router = Router();

  router.get('/products', (req) async {
    // Create ProductDto (shared with Flutter)
    final product = ProductDto(
      id: '1',
      name: 'MacBook Pro',
      price: 2499.99,
    );
    
    return Response.json(product.toJson());
  });

  app.use(router);
  await app.listen(port: 3000);
}
```

### Mobile (apps/mobile/lib/main.dart)

```dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:models/models.dart';

Future<ProductDto> fetchProduct() async {
  final response = await http.get(
    Uri.parse('http://localhost:3000/products'),
  );
  
  // Parse using shared DTO
  return ProductDto.fromJson(json.decode(response.body));
}
```

## Shared Models (packages/models)

The models package contains DTOs that are used by both backend and mobile:

```dart
class ProductDto {
  final String id;
  final String name;
  final double price;
  final String? description;

  ProductDto({
    required this.id,
    required this.name,
    required this.price,
    this.description,
  });

  // JSON serialization for backend
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'description': description,
  };

  // JSON deserialization for mobile
  factory ProductDto.fromJson(Map<String, dynamic> json) => ProductDto(
    id: json['id'],
    name: json['name'],
    price: json['price'],
    description: json['description'],
  );
}
```

## Development Workflow

1. **Update Models**: Edit DTOs in `packages/models/`
2. **Backend Changes**: Both backend and mobile automatically see the changes
3. **Type Safety**: Compile errors if data structures don't match
4. **Hot Reload**: Both backend (with `--enable-vm-service`) and Flutter support hot reload

## Melos Scripts

```bash
# Analyze all packages
melos run analyze

# Run all tests
melos run test

# Format all code
melos run format

# Start backend server
melos run backend:start

# Run Flutter app
melos run mobile:run
```

## Next Steps

- Add more shared DTOs to `packages/models`
- Implement authentication with shared user models
- Add validation logic to shared models
- Create shared validation rules
- Add more endpoints to the backend
- Build out the mobile UI
