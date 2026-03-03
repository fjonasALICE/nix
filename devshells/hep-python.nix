{ pkgs }: pkgs.mkShell {
  # nix develop ~/nix#"hep-python"
  packages = [
    pkgs.lhapdf
    pkgs.fastjet
    pkgs.pythia
    pkgs.root
    pkgs.fastjet-contrib
    (pkgs.python313.withPackages (ps: with ps; [
      ps.numpy
      ps.scipy
      ps.matplotlib
      ps.pandas
      ps.ipython
      ps.scienceplots
    ]))
  ];

  shellHook = ''
    export DEV_SHELL_NAME="hep-python"
    export HEP_CXX="${pkgs.stdenv.cc}/bin/c++"
    export HEP_PYTHIA="${pkgs.pythia}"
    export HEP_FASTJET="${pkgs.fastjet}"
    export HEP_LHAPDF="${pkgs.lhapdf}"
    export HEP_ROOT="${pkgs.root}"

    # Extend LHAPDF_DATA_PATH with analysis PDFs directory
    export LHAPDF_DATA_PATH="/Users/florianjonas/analysis/INCNLOSmallSystems/pdfs''${LHAPDF_DATA_PATH:+:$LHAPDF_DATA_PATH}"

    # Force an interactive zsh prompt if entered from another shell.
    if [ -z "''${ZSH_VERSION-}" ] && command -v zsh >/dev/null 2>&1; then
      exec zsh -i
    fi

    echo "hep dev shell [❄ $DEV_SHELL_NAME]  –  pythia · fastjet · fastjet-contrib · lhapdf · root · python3.13 (numpy, scipy, matplotlib, pandas, ipython)"
    echo "  make <name>   compile <name>.cc in the current directory"
  '';
}

