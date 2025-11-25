# tmp_project

A NeutronX backend application.

## Getting Started

### Installation

```bash
dart pub get
```

### Running in Development

```bash
neutron dev
# add compile-time defines or disable watching:
# neutron dev -DAPI_URL=https://api.dev --watch=false
# or
dart run bin/server.dart
```

### Building for Production

```bash
neutron build
# pass defines/arch:
# neutron build -DAPI_URL=https://api.prod --target-arch=arm64
# or
dart compile exe bin/server.dart -o build/server
```

### Running Tests

```bash
dart test
```

## Project Structure

```
tmp_project/
├── bin/
│   └── server.dart       # Application entry point
├── lib/
│   ├── tmp_project.dart
│   └── src/
│       ├── modules/      # Feature modules (self-contained)
│       │   ├── modules.dart        # Module registry (auto-adds generated modules)
│       │   └── home/               # Example module
│       │       ├── controllers/
│       │       ├── home_module.dart
│       │       ├── services/
│       │       └── repositories/
│       ├── controllers/  # Bare controllers (optional)
│       │   └── controllers.dart    # Manual controller registry
│       └── middleware/   # Custom middleware
└── test/                 # Tests
```

## Documentation

- [NeutronX Documentation](https://github.com/neutronx-labs/neutronx.git)
