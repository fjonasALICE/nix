{ pkgs, ... }: {

  # ── PATH ──────────────────────────────────────────────────────────────────
  # nix-darwin hard-codes PATH in set-environment, bypassing macOS path_helper.
  # Re-add Homebrew paths that path_helper would have included via /etc/paths.d.
  environment.systemPath = [ "/opt/homebrew/bin" "/opt/homebrew/sbin" ];

  # ── System ────────────────────────────────────────────────────────────────
  # Allow unfree packages (e.g. some fonts, drivers)
  nixpkgs.config.allowUnfree = true;

  # Custom packages (e.g. NNLOJET) — not in nixpkgs
  nixpkgs.overlays = [
    (self: super: {
      nnlojet = super.callPackage ./custompackages/nnlojet/default.nix { };
    })
  ];

  # Determinate Nix manages its own daemon — disable nix-darwin's Nix management
  # to avoid conflicts. Flakes/nix-command are already enabled by Determinate.
  # See: https://docs.determinate.systems/guides/nix-darwin/
  nix.enable = false;

  # Determinate Nix custom configuration
  # This writes to /etc/nix/nix.custom.conf which is included by Determinate's main config.
  # See: https://docs.determinate.systems/determinate-nix/#determinate-nix-configuration
  environment.etc."nix/nix.custom.conf".text = ''
    # Use all available CPU cores for parallel compilation within each build
    cores = 14
  '';

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
      "mas"
    ];
    casks = [
      "iterm2"
      "kopiaui"
    ];

    masApps = {
      "Mattermost Desktop" = 1614666244;
    };
  };

  # ── Platform ──────────────────────────────────────────────────────────────
  nixpkgs.hostPlatform = "aarch64-darwin";
  system.stateVersion = 6;
}
