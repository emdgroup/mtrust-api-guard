# Generating API Documentation for Git References

This document demonstrates how to use the new git reference functionality in mtrust_api_guard.

## Basic Usage

### Generate documentation for a specific branch

```bash
# Generate and cache API documentation for the 'main' branch
mtrust_api_guard generate --ref main

# Generate and cache API documentation for a feature branch
mtrust_api_guard generate --ref feature/new-api
```

### Generate documentation for a specific commit

```bash
# Generate and cache API documentation for a specific commit
mtrust_api_guard generate --ref abc1234

# Generate and cache API documentation for a tag
mtrust_api_guard generate --ref v1.0.0
```

### Generate documentation for current HEAD

```bash
# Generate documentation for current state (no ref specified)
mtrust_api_guard generate
```

## Comparing References

### Compare two branches

```bash
# Compare main branch with current HEAD
mtrust_api_guard compare --base main --new HEAD

# Compare two specific branches
mtrust_api_guard compare --base develop --new feature/new-api
```

### Compare with commit history

```bash
# Compare current state with a previous commit
mtrust_api_guard compare --base abc1234 --new HEAD

# Compare two specific commits
mtrust_api_guard compare --base v1.0.0 --new v1.1.0
```

## Safety Features

The tool includes several safety features to prevent data loss:

1. **Uncommitted Changes Check**: If you have uncommitted changes and try to use `--ref`, the tool will error out
2. **Automatic State Restoration**: After generating documentation for a ref, the tool automatically restores your original git state
3. **Cache Validation**: The tool validates that generated documentation is properly cached before proceeding

## Cache Management

The cache is automatically managed and located at `~/.mtrust_api_guard/cache/`:

```bash
# View cached references for current repository
ls ~/.mtrust_api_guard/cache/$(basename $(git rev-parse --show-toplevel))/

# Clear cache for current repository
rm -rf ~/.mtrust_api_guard/cache/$(basename $(git rev-parse --show-toplevel))/
```

## CI/CD Integration

In CI/CD pipelines, you can now use git references directly:

```yaml
- name: Compare API changes
  run: |
    mtrust_api_guard compare --base main --new ${{ github.sha }}
```

This eliminates the need to check in generated API files and prevents merge conflicts.
