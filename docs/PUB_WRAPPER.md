# NeutronX Pub Wrapper

This wrapper allows you to use `sdk: neutronx` syntax in your pubspec.yaml files.

## How It Works

The wrapper intercepts `dart pub` commands and temporarily transforms:

```yaml
dependencies:
  neutronx:
    sdk: neutronx
```

Into:

```yaml
dependencies:
  neutronx:
    path: /your/neutronx/path
```

Before running pub, then restores the original after.

## Setup

### 1. Make sure NEUTRONX_ROOT is set

```bash
export NEUTRONX_ROOT="/Users/yourname/neutronx"
```

### 2. Create alias for neutron-pub

Add to your `~/.zshrc` or `~/.bashrc`:

```bash
alias pub='$NEUTRONX_ROOT/bin/neutron-pub'
```

Or add to PATH:

```bash
export PATH="$NEUTRONX_ROOT/bin:$PATH"
```

## Usage

### With SDK Syntax (using wrapper)

**pubspec.yaml:**
```yaml
dependencies:
  neutronx:
    sdk: neutronx
```

**Commands:**
```bash
neutron-pub get      # Instead of dart pub get
neutron-pub upgrade
neutron-pub outdated
```

### Without Wrapper (standard approach)

**pubspec.yaml:**
```yaml
dependencies:
  neutronx:
    path: /Users/yourname/neutronx  # Or auto-generated when NEUTRONX_ROOT is set
```

**Commands:**
```bash
dart pub get         # Standard dart pub works
dart pub upgrade
```

## Pros and Cons

### Using Wrapper (sdk: neutronx syntax)

**Pros:**
- ✅ Clean syntax: `sdk: neutronx`
- ✅ Looks like Flutter SDK
- ✅ Hides implementation details

**Cons:**
- ❌ Requires wrapper script
- ❌ Must use `neutron-pub` instead of `dart pub`
- ❌ IDE might not understand SDK reference
- ❌ Adds complexity

### Standard Approach (path dependency)

**Pros:**
- ✅ Works with standard `dart pub` commands
- ✅ IDE understands path dependencies
- ✅ Transparent - shows actual path
- ✅ No wrapper needed
- ✅ Simpler

**Cons:**
- ❌ Longer pubspec syntax
- ❌ Shows implementation detail (path)

## Recommendation

**Use the standard path approach** (without wrapper) because:

1. It's simpler and more transparent
2. IDEs understand it natively
3. No special commands needed
4. Industry standard for local development
5. The CLI auto-generates it when `NEUTRONX_ROOT` is set

The wrapper is provided as an option if you really want `sdk: neutronx` syntax, but it adds unnecessary complexity for minimal benefit.

## Examples

### Standard Approach (Recommended)

```bash
# Set environment variable
export NEUTRONX_ROOT="/Users/you/neutronx"

# Create project - auto-generates path dependency
neutron new my_app
cd my_app

# Standard pub commands work
dart pub get
dart pub upgrade
```

Generated pubspec.yaml:
```yaml
dependencies:
  neutronx:
    path: /Users/you/neutronx
```

### Wrapper Approach (Optional)

```bash
# Set environment variable
export NEUTRONX_ROOT="/Users/you/neutronx"

# Create project with sdk syntax
neutron new my_app --sdk-syntax
cd my_app
```

Edit pubspec.yaml manually:
```yaml
dependencies:
  neutronx:
    sdk: neutronx
```

Then use wrapper:
```bash
neutron-pub get      # Use wrapper instead of dart pub
neutron-pub upgrade
```

## Technical Details

The wrapper uses `sed` to find and replace the SDK reference before calling `dart pub`. A backup is created and automatically restored after the command completes.

For production use, a more robust YAML parser (like `yq`) could be used instead of `sed`.
