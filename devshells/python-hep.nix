{ pkgs }: pkgs.mkShell {
  # nix develop ~/nix#"python-hep"
  packages = [
    pkgs.lhapdf
    (pkgs.python313.withPackages (ps: with ps; [
      numpy
      matplotlib
      scienceplots
      ipython
    ]))
  ];

  shellHook = ''
    export DEV_SHELL_NAME="python-hep"
    export HEP_LHAPDF="${pkgs.lhapdf}"

    # Make LHAPDF data discoverable by default.
    export LHAPDF_DATA_PATH="${pkgs.lhapdf}/share/LHAPDF''${LHAPDF_DATA_PATH:+:$LHAPDF_DATA_PATH}"

    # Force an interactive zsh prompt if entered from another shell.
    if [ -z "''${ZSH_VERSION-}" ] && command -v zsh >/dev/null 2>&1; then
      exec zsh -i
    fi

    echo "python-hep dev shell [❄ $DEV_SHELL_NAME]  –  python3.13 (numpy, matplotlib, scienceplots) + lhapdf"
  '';
}
