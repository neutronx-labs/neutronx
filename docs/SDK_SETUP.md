# NeutronX SDK Setup

This guide explains how to set up NeutronX as an SDK (similar to Flutter).

## What is the NeutronX SDK?

Like Flutter SDK, NeutronX can be referenced in your projects without specifying paths or versions:

```yaml
dependencies:
  neutronx:
    sdk: neutronx
```

## Setup Instructions

### 1. Clone NeutronX

```bash
git clone https://github.com/neutronx-labs/neutronx.git
# Or your preferred location
cd neutronx
```

### 2. Set Environment Variable

Add the `NEUTRONX_ROOT` environment variable pointing to your NeutronX directory.

#### macOS/Linux (Bash/Zsh)

Add to your `~/.zshrc` or `~/.bashrc`:

```bash
export NEUTRONX_ROOT="$HOME/neutronx"
export PATH="$PATH:$NEUTRONX_ROOT/bin"
```

Then reload:
```bash
source ~/.zshrc  # or source ~/.bashrc
```

#### Windows (PowerShell)

Add to your PowerShell profile:

```powershell
$env:NEUTRONX_ROOT = "C:\neutronx"
$env:PATH += ";$env:NEUTRONX_ROOT\bin"
```

### 3. Verify Installation

```bash
echo $NEUTRONX_ROOT
# Should print: /Users/yourname/neutronx (or your path)

neutron --version
# Should print: NeutronX CLI version 0.1.0
```

### 4. Install CLI Globally

```bash
cd $NEUTRONX_ROOT
./install_cli.sh
```

## Using NeutronX SDK in Projects

### Create New Project

```bash
neutron new my_backend
cd my_backend
```

The generated `pubspec.yaml` will include:

```yaml
dependencies:
  neutronx:
    sdk: neutronx
```

### Dart Configuration

Create a `dart_tool/package_config.json` entry or let pub resolve it automatically when `NEUTRONX_ROOT` is set.

## How It Works

1. **Environment Variable**: `NEUTRONX_ROOT` points to your NeutronX installation
2. **SDK Reference**: Projects use `sdk: neutronx` instead of path or git dependencies
3. **Pub Resolution**: Dart's pub tool reads `NEUTRONX_ROOT` and resolves the SDK package

## Advantages

- ✅ No path dependencies in pubspec.yaml
- ✅ Single NeutronX installation for all projects
- ✅ Easy version management (git pull to update)
- ✅ Similar to Flutter's SDK model
- ✅ Clean, portable pubspec files

## Updating NeutronX

```bash
cd $NEUTRONX_ROOT
git pull origin main
dart pub get
```

All your projects automatically use the updated version!

## Alternative: Published Package

Once NeutronX is published to pub.dev, you can use:

```yaml
dependencies:
  neutronx: ^0.1.0
```

This doesn't require SDK setup but requires publishing updates to pub.dev.

## Troubleshooting

### "Package neutronx has no sdk" error

Make sure `NEUTRONX_ROOT` is set:
```bash
echo $NEUTRONX_ROOT
```

### CLI not found

Add NeutronX bin to PATH:
```bash
export PATH="$PATH:$NEUTRONX_ROOT/bin"
```

### Projects not finding NeutronX

1. Check environment variable: `echo $NEUTRONX_ROOT`
2. Verify NeutronX exists: `ls $NEUTRONX_ROOT`
3. Try absolute path in pubspec temporarily:
   ```yaml
   dependencies:
     neutronx:
       path: /absolute/path/to/neutronx
   ```
