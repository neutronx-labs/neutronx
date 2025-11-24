# Using NeutronX CLI for Development

## Option 1: Published Package (Future)

Once NeutronX is published to pub.dev, projects will automatically work:

```yaml
dependencies:
  neutronx: ^0.1.0
```

## Option 2: Git Dependency (Current Default)

The CLI generates projects with a git dependency:

```yaml
dependencies:
  neutronx:
    git:
  url: https://github.com/neutronx-labs/neutronx.git
      ref: main
```

This works if the repository is public and accessible.

## Option 3: Local Development Path

For local development with NeutronX, update your project's `pubspec.yaml`:

```yaml
dependencies:
  neutronx:
    path: /absolute/path/to/neutronx
```

**Example**:

```yaml
dependencies:
  neutronx:
    path: /Users/nikhil/NeutronX
```

### Steps for Local Development:

1. Create your project:
   ```bash
   neutron new my_backend
   cd my_backend
   ```

2. Edit `pubspec.yaml` and replace the git dependency with a local path:
   ```yaml
   dependencies:
     neutronx:
       path: /Users/nikhil/NeutronX  # Use your actual path
   ```

3. Install dependencies:
   ```bash
   dart pub get
   ```

4. Run your server:
   ```bash
   neutron dev
   ```

## Finding Your NeutronX Path

```bash
# If you cloned NeutronX
cd /path/to/where/you/cloned/neutronx
pwd
# Copy this output and use it as the path value
```

## Monorepo Projects

For monorepo projects, the backend `pubspec.yaml` will also need the same update:

```bash
neutron new my_app --monorepo
cd my_app/apps/backend
```

Edit `apps/backend/pubspec.yaml`:

```yaml
dependencies:
  neutronx:
    path: /absolute/path/to/neutronx  # Your path here
  models:
    path: ../../packages/models
```

## Why This Happens

During development, NeutronX is not yet published to pub.dev. The CLI defaults to using a git dependency, but for local development you'll need to use a path dependency pointing to your local NeutronX repository.

Once NeutronX is published to pub.dev, projects will automatically work without any path configuration!
