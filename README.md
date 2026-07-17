# Crystal Nix (flake)

## Features

- `nix develop` → dev shell with Crystal binary
- `nix run` → run Crystal binary directly
- `nix build .#crystal-binary` → binary package
- `nix build .#crystal-source` → build from source

## Commands

```bash
nix develop
crystal --version

nix run
nix build .#crystal-binary
nix build .#crystal-source
```

## Targets
This flake currently targets only **Linux (x86_64)** .
