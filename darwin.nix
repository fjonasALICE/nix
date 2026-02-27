{ pkgs, ... }: {

  # ── PATH ──────────────────────────────────────────────────────────────────
  # nix-darwin hard-codes PATH in set-environment, bypassing macOS path_helper.
  # Re-add Homebrew paths that path_helper would have included via /etc/paths.d.
  environment.systemPath = [ "/opt/homebrew/bin" "/opt/homebrew/sbin" ];

  # ── System ────────────────────────────────────────────────────────────────
  # Allow unfree packages (e.g. some fonts, drivers)
  nixpkgs.config.allowUnfree = true;

  # Determinate Nix manages its own daemon — disable nix-darwin's Nix management
  # to avoid conflicts. Flakes/nix-command are already enabled by Determinate.
  nix.enable = false;

  # ── macOS defaults ────────────────────────────────────────────────────────
  # system.primaryUser is required for user-scoped defaults (dock, finder, etc.)
  system.primaryUser = "florianjonas";

  system.defaults = {
    dock.autohide = true;
    finder.AppleShowAllExtensions = true;
    NSGlobalDomain.AppleShowAllExtensions = true;
  };

  # ── Shell ─────────────────────────────────────────────────────────────────
  # Set zsh as the default shell for florianjonas
  users.users.florianjonas.home  = "/Users/florianjonas";
  users.users.florianjonas.shell = pkgs.zsh;
  programs.zsh.enable = true;

  # ── Fonts ─────────────────────────────────────────────────────────────────
  # Fonts must be declared here (not home.nix) so nix-darwin copies them into
  # a path macOS font discovery actually scans.
  fonts.packages = with pkgs.nerd-fonts; [
    hack
    iosevka
    iosevka-term
  ];

  # ── Homebrew (remaining packages with no nix equivalent) ──────────────────
  # onActivation.cleanup = "zap" removes any cask/formula not listed here.
  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";
    brews = [
      "alisw/system-deps/alibuild"
      "alisw/system-deps/o2-full-deps"
    ];
    casks = [
      "iterm2"
      "kopiaui"
    ];
  };

  # ── Platform ──────────────────────────────────────────────────────────────
  nixpkgs.hostPlatform = "aarch64-darwin";
  system.stateVersion = 6;
}
