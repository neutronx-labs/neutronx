# Making NeutronX a Custom SDK

## Goal
Make `sdk: neutronx` work in pubspec.yaml like `sdk: flutter`

## Current Dart SDK Support

Dart's pub tool has hardcoded support for only these SDKs:
- `dart` - Built into Dart SDK
- `flutter` - Recognized when `FLUTTER_ROOT` is set

## Approaches to Add Custom SDK

### 1. ❌ Modify Dart SDK (Not Feasible)
Would require forking and maintaining Dart SDK itself.

### 2. ✅ Environment Variable + Path (Current Solution)
Our current approach using `NEUTRONX_ROOT`:
```yaml
dependencies:
  neutronx:
    path: $NEUTRONX_ROOT  # Resolved via environment variable
```

**Pros**: Works immediately, no Dart modifications needed
**Cons**: Not exactly `sdk: neutronx` syntax

### 3. 🔧 Custom Pub Tool (Advanced)

Create a wrapper around `dart pub` that recognizes `sdk: neutronx`:

#### Step 1: Create pub wrapper script

```bash
#!/bin/bash
# File: bin/neutron-pub

# Intercept pub commands
if [ "$1" == "get" ] || [ "$1" == "upgrade" ]; then
    # Transform pubspec.yaml temporarily
    python3 scripts/transform_pubspec.py
    dart pub "$@"
    python3 scripts/restore_pubspec.py
else
    dart pub "$@"
fi
```

#### Step 2: Transform pubspec.yaml

```python
# scripts/transform_pubspec.py
import yaml
import os

with open('pubspec.yaml', 'r') as f:
    data = yaml.safe_load(f)

# Backup original
with open('pubspec.yaml.backup', 'w') as f:
    yaml.dump(data, f)

# Transform sdk: neutronx to path: $NEUTRONX_ROOT
neutronx_root = os.environ.get('NEUTRONX_ROOT')
if 'neutronx' in data.get('dependencies', {}):
    dep = data['dependencies']['neutronx']
    if isinstance(dep, dict) and dep.get('sdk') == 'neutronx':
        data['dependencies']['neutronx'] = {'path': neutronx_root}

with open('pubspec.yaml', 'w') as f:
    yaml.dump(data, f)
```

**Pros**: Allows `sdk: neutronx` syntax
**Cons**: Requires wrapper script, adds complexity

### 4. 🎯 Pub Server with SDK Support (Most Correct)

Implement a custom pub server that understands custom SDKs:

1. **Run local pub server**: `pub_server` package
2. **Register SDK mapping**: Server knows `sdk: neutronx` → path
3. **Configure pub to use server**: `PUB_HOSTED_URL`

This is how enterprise teams add custom package sources.

### 5. ✨ Dart Tool Hook (Ideal Future Solution)

Dart could add official support for custom SDKs via configuration:

**Proposed: `~/.dart_tool/sdk_config.yaml`**
```yaml
custom_sdks:
  neutronx:
    path: /Users/you/neutronx
    version: 0.1.0
```

Then `sdk: neutronx` would work! But this requires:
- Dart team to implement the feature
- Submit feature request to dart-lang/sdk

## Recommended Solution for NeutronX

**Current best approach**: Keep using `NEUTRONX_ROOT` with automatic path resolution.

### Why?

1. ✅ **Works immediately** - No Dart modifications needed
2. ✅ **Simple** - Just set environment variable
3. ✅ **Transparent** - Users see actual path in generated pubspec
4. ✅ **No wrappers** - Direct dart/pub commands work
5. ✅ **IDE compatible** - VS Code, IntelliJ understand path dependencies

### Implementation

```dart
// In CLI template generator
String get pubspecYaml {
  final neutronxRoot = Platform.environment['NEUTRONX_ROOT'];
  
  if (neutronxRoot != null && neutronxRoot.isNotEmpty) {
    return '''
dependencies:
  neutronx:
    path: $neutronxRoot
''';
  } else {
    return '''
dependencies:
  neutronx: ^0.1.0  # Change to path when using local SDK
''';
  }
}
```

## Future: When to Use True SDK Syntax?

Only when one of these happens:

1. **Dart adds SDK plugin API** - Official way to register custom SDKs
2. **NeutronX becomes official** - Dart team adds built-in support
3. **Use pub server** - For enterprise with custom infrastructure

Until then, environment variable + path is the **best practice** used by:
- Internal corporate frameworks
- Pre-release testing of packages
- Local development workflows

## Alternative: Published Package

Once published to pub.dev:
```yaml
dependencies:
  neutronx: ^0.1.0
```

This is simpler but requires publishing every update.

## Comparison

| Approach | Syntax | Complexity | Works Today? |
|----------|--------|------------|--------------|
| NEUTRONX_ROOT + path | ⭐⭐⭐⭐ Good | ⭐⭐⭐⭐⭐ Simple | ✅ Yes |
| sdk: neutronx (built-in) | ⭐⭐⭐⭐⭐ Perfect | ❌ Requires Dart changes | ❌ No |
| Wrapper script | ⭐⭐⭐⭐ Good | ⭐⭐ Complex | ✅ Yes |
| Pub server | ⭐⭐⭐ OK | ⭐ Very Complex | ✅ Yes |
| Published package | ⭐⭐⭐⭐ Good | ⭐⭐⭐⭐⭐ Simple | ✅ Yes |

**Recommendation**: Stick with current `NEUTRONX_ROOT` approach. It's the industry standard for local SDK development.
