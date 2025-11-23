# NeutronX Pub Integration

The NeutronX CLI includes integrated pub support that allows you to use `sdk: neutronx` syntax in your pubspec.yaml files.

## How It Works

The `neutron pub` command intercepts pub commands and temporarily transforms:

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

Before running pub, then automatically restores the original after.

## Setup

### 1. Make sure NEUTRONX_ROOT is set

```bash
export NEUTRONX_ROOT="/Users/yourname/neutronx"
```

### 2. Install the CLI

```bash
cd neutronx
./install_cli.sh
```

That's it! No additional configuration needed.

## Usage

### With SDK Syntax

**pubspec.yaml:**
```yaml
dependencies:
  neutronx:
    sdk: neutronx
```

**Commands:**
```bash
neutron pub get       # Transforms, runs pub get, restores
neutron pub upgrade   # Transforms, runs pub upgrade, restores
neutron pub outdated  # Transforms, runs pub outdated, restores
neutron pub deps      # Works with any pub command!
```

### Without neutron pub (standard approach)

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

### Using `neutron pub` (sdk: neutronx syntax)

**Pros:**
- ✅ Clean syntax: `sdk: neutronx`
- ✅ Looks like Flutter SDK
- ✅ Hides implementation details
- ✅ Integrated into neutron CLI
- ✅ Automatic transformation and restoration

**Cons:**
- ❌ Must use `neutron pub` instead of `dart pub`
- ❌ IDE might not understand SDK reference (shows error)
- ❌ Adds slight complexity

### Standard Approach (path dependency)

**Pros:**
- ✅ Works with standard `dart pub` commands
- ✅ IDE understands path dependencies (no errors)
- ✅ Transparent - shows actual path
- ✅ Simpler

**Cons:**
- ❌ Longer pubspec syntax
- ❌ Shows implementation detail (path)

## Recommendation

**Choose based on your preference:**

- **Want clean syntax?** Use `sdk: neutronx` with `neutron pub` commands
- **Want IDE compatibility?** Use auto-generated path dependency (CLI does this when NEUTRONX_ROOT is set)

## Examples

### Approach 1: Auto-Generated Path (Recommended for IDE compatibility)

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

### Approach 2: SDK Syntax (Clean syntax)

```bash
# Set environment variable
export NEUTRONX_ROOT="/Users/you/neutronx"

# Create project
neutron new my_app
cd my_app
```

Edit pubspec.yaml manually:
```yaml
dependencies:
  neutronx:
    sdk: neutronx
```

Then use `neutron pub`:
```bash
neutron pub get      # Transforms, runs, restores
neutron pub upgrade
neutron pub outdated
```

## Technical Details

The `neutron pub` command:

1. Detects `sdk: neutronx` in pubspec.yaml
2. Creates a backup (.pubspec.yaml.neutron-backup)
3. Transforms SDK reference to `path: $NEUTRONX_ROOT`
4. Runs the dart pub command
5. Automatically restores original pubspec.yaml
6. Deletes backup

This ensures your source pubspec.yaml always stays clean with `sdk: neutronx` syntax.
