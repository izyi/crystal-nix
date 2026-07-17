# Crystal Nix (flake)

## Features

- `nix develop` → dev shell with Crystal binary
- `nix run` → run Crystal binary directly
- `nix build .#crystal-binary` → binary package
- `nix build .#crystal-source` → build from source
- GitHub Action auto-updates latest version, hashes, and libc metadata

## Commands

```bash
nix develop
crystal --version

nix run
nix build .#crystal-binary
nix build .#crystal-source
```

## Auto-update metadata

Workflow rewrites only the block in `flake.nix` between:

- `# BEGIN AUTO-GENERATED CRYSTAL METADATA`
- `# END AUTO-GENERATED CRYSTAL METADATA`

## Termux note

Termux is `aarch64-android` and uses **bionic** libc (not glibc/musl).
This flake currently targets Linux + Darwin only.
