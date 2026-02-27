# Personal Nix Configuration

My personal Nix configuration for macOS.

## Structure

- `flake.nix` - Flake entry point
- `darwin.nix` - System settings, Homebrew packages, fonts, and custom package overlay
- `home.nix` - User packages and Home Manager configuration
- `config/` - Editor and shell configuration (dotfiles)
- `custompackages/` - Custom Nix packages (not in nixpkgs), exposed via overlay in `darwin.nix` — see [custompackages/README.md](custompackages/README.md)
- `devshells/` - Development environment definitions

## Cheatsheet

```bash
# Rebuild system configuration
darwin-rebuild switch --flake ~/nix
# or with nh:
nh darwin switch ~/nix

# Update flake inputs
nix flake update

# Search for packages
nix search nixpkgs <package-name>

# Garbage collection
nix-collect-garbage -d
```

