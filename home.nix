{ pkgs, lib, ... }: {

  home.username    = "florianjonas";
  home.homeDirectory = "/Users/florianjonas";

  # ── Packages ──────────────────────────────────────────────────────────────
  home.packages = [
    # Core utilities
    pkgs.git
    pkgs.curl
    pkgs.wget
    pkgs.ripgrep
    pkgs.jq
    pkgs.coreutils

    # Modern CLI replacements
    pkgs.bat
    pkgs.eza
    pkgs.ncdu
    pkgs.btop
    pkgs.tldr

    # Dev tools
    pkgs.gh
    pkgs.lazygit
    pkgs.tmux
    pkgs.nodejs_20
    pkgs.pandoc
    pkgs.code-cursor
    pkgs.nh

    # Apps / services
    pkgs.opencode
    pkgs.yatto
    pkgs.backrest
    pkgs.taskspooler
    pkgs.languagetool
    pkgs.zathura
    pkgs.bitwarden-desktop

    # Physics / HEP
    pkgs.lhapdf

    # Shell / terminal
    pkgs.zellij
    pkgs.atuin
    pkgs.pueue

    # GUI / other
    pkgs.firefox
    pkgs.texliveFull
    pkgs.root
  ];

  # ── Managed files ─────────────────────────────────────────────────────────
  # ~/.p10k.zsh is a read-only symlink to the nix store.
  # To reconfigure: remove this line, rebuild, run `p10k configure`,
  # then `cp ~/.p10k.zsh ~/nix/.p10k.zsh`, re-add this line and rebuild.
  home.file.".p10k.zsh" = {
    source = ./config/p10k/.p10k.zsh;
    force = true;
  };

  # Neovim config: manage ~/.config/nvim via Home Manager.
  # The actual config lives in ./config/nvim (migrated from ~/.config/nvim).
  xdg.configFile."nvim".source = ./config/nvim;

  # Zellij config: manage ~/.config/zellij/config.kdl via Home Manager.
  xdg.configFile."zellij/config.kdl" = {
    source = ./config/zellij/config.kdl;
    force = true;
  };

  # Zellij plugins (zjstatus powerline status bar), managed via Nix.
  xdg.configFile."zellij/plugins/zjstatus.wasm".source =
    pkgs.fetchurl {
      url = "https://github.com/dj95/zjstatus/releases/download/v0.22.0/zjstatus.wasm";
      sha256 = "0lyxah0pzgw57wbrvfz2y0bjrna9bgmsw9z9f898dgqw1g92dr2d";
    };

  # ── Zsh ───────────────────────────────────────────────────────────────────
  programs.zsh = {
    enable = true;

    history = {
      size       = 50000;
      save       = 50000;
      ignoreDups = true;
      share      = true;
    };

    shellAliases = {
      nixu = "nix flake update --flake ~/nix";
      nixb = "nh darwin switch ~/nix";
      nixe = "nvim ~/nix/darwin.nix";
      pip  = "pip3";
    };

    zplug = {
      enable  = true;
      plugins = [
        { name = "romkatv/powerlevel10k"; tags = [ "as:theme" "depth:1" ]; }
        { name = "zsh-users/zsh-autosuggestions"; }
        { name = "zsh-users/zsh-syntax-highlighting"; }
        { name = "fdellwing/zsh-bat"; }
        { name = "plugins/git"; tags = [ "from:oh-my-zsh" ]; }
      ];
    };

    initContent = lib.mkMerge [
      # p10k instant prompt must be sourced as early as possible.
      (lib.mkBefore ''
        if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
          source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
        fi
      '')

      # Sourced after zplug plugins, aliases, and tool init.
      (lib.mkAfter ''
        # Shell functions (nixd stays with nix — nh has no develop equivalent)
        nixs() { nh search "''${1:-default}"; }
        nixd() { nix develop ~/nix#"''${1:-default}"; }

        # Research environment — sourced conditionally since paths are local installs

        export ALIBUILD_WORK_DIR="$HOME/alice/sw"
        command -v alienv &>/dev/null && eval "$(alienv shell-helper)"

        export PATH="/Users/florianjonas/Library/Python/3.9/bin:$PATH"
        export PATH="/Users/florianjonas/analysis/fastjet-3.3.4/build/bin:$PATH"
        export PATH="/Users/florianjonas/analysis/nnlojet-v1.0.2/install/bin:$PATH"
        [[ -f "/Users/florianjonas/analysis/nnlojet-v1.0.2/install/share/nnlojet-completion.sh" ]] && \
          source "/Users/florianjonas/analysis/nnlojet-v1.0.2/install/share/nnlojet-completion.sh"

        # Secrets (not managed by nix — keep out of git)
        [[ -f ~/.zshrc.secrets ]] && source ~/.zshrc.secrets

        # Tool init
        eval "$(atuin init zsh)"
        test -e "''${HOME}/.iterm2_shell_integration.zsh" && source "''${HOME}/.iterm2_shell_integration.zsh"

        # p10k theme config
        [[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
      '')
    ];
  };

  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    withNodeJs = true;
    withPython3 = true;
  };

  programs.nix-spotlight.enable = true;

  # Required by home-manager — do not change after first activation.
  home.stateVersion = "24.11";
}
