# NeutronX Quick Reference

## Two Ways to Use NeutronX

### Option 1: Auto-Generated Path (IDE-Friendly) ⭐ Recommended

**Setup:**
```bash
export NEUTRONX_ROOT="/Users/yourname/neutronx"
```

**Create Project:**
```bash
neutron new my_app
cd my_app
```

**Generated pubspec.yaml:**
```yaml
dependencies:
  neutronx:
    path: /Users/yourname/neutronx  # Auto-generated!
```

**Use standard pub:**
```bash
dart pub get
dart pub upgrade
```

**Pros:** ✅ IDE understands it ✅ No special commands ✅ Transparent

---

### Option 2: SDK Syntax (Clean Syntax)

**Setup:**
```bash
export NEUTRONX_ROOT="/Users/yourname/neutronx"
```

**Create Project & Edit pubspec.yaml:**
```yaml
dependencies:
  neutronx:
    sdk: neutronx  # Clean syntax!
```

**Use neutron pub:**
```bash
neutron pub get       # Transforms → runs → restores
neutron pub upgrade
neutron pub outdated
```

**Pros:** ✅ Clean syntax ✅ Looks like Flutter ✅ Automatic handling

**Cons:** ❌ IDE shows error (until pub get runs) ❌ Must use `neutron pub`

---

## Commands Quick Reference

```bash
# Create projects
neutron new my_backend
neutron new my_app --monorepo

# Generate code
neutron generate module users
neutron generate dto product
neutron generate service auth
neutron generate repository orders

# Development
neutron dev
neutron dev --port 3000

# Build
neutron build
neutron build --output bin/server

# Pub commands (for sdk: neutronx syntax)
neutron pub get
neutron pub upgrade
neutron pub outdated

# Help
neutron --help
neutron <command> --help
```

## Installation

```bash
# 1. Clone NeutronX
git clone https://github.com/neutronx-labs/neutronx.git
cd neutronx

# 2. Run installer
./install_cli.sh

# 3. Add to ~/.zshrc or ~/.bashrc
export NEUTRONX_ROOT="/Users/yourname/neutronx"
export PATH="$PATH:$HOME/.pub-cache/bin"

# 4. Reload shell
source ~/.zshrc
```

## Verify Installation

```bash
neutron --version
echo $NEUTRONX_ROOT
```

## Which Approach Should I Use?

| Aspect | Auto-Path | SDK Syntax |
|--------|-----------|------------|
| Syntax | `path: /Users/...` | `sdk: neutronx` |
| IDE Support | ✅ Full | ⚠️ Shows error |
| Pub Commands | `dart pub get` | `neutron pub get` |
| Simplicity | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| Aesthetics | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |

**Recommendation:** Start with Auto-Path (Option 1) for best IDE experience!
