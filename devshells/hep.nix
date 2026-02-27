{ pkgs }: pkgs.mkShell {
  # nix develop ~/nix#hep
  # Then from any directory with a foo.cc: make foo
  packages = [
    pkgs.lhapdf
    pkgs.fastjet
    pkgs.pythia
    pkgs.root
    pkgs.fastjet-contrib
  ];
  shellHook = ''
    export DEV_SHELL_NAME="hep"
    export HEP_CXX="${pkgs.stdenv.cc}/bin/c++"
    export HEP_PYTHIA="${pkgs.pythia}"
    export HEP_FASTJET="${pkgs.fastjet}"
    export HEP_LHAPDF="${pkgs.lhapdf}"
    export HEP_ROOT="${pkgs.root}"
    # make reads MAKEFILES automatically, so `make foo` compiles
    # foo.cc with all HEP libs from any directory.
    export MAKEFILES="${./hep-GNUmakefile}"
    # Force an interactive zsh prompt if entered from another shell.
    if [ -z "''${ZSH_VERSION-}" ] && command -v zsh >/dev/null 2>&1; then
      exec zsh -i
    fi

    echo "hep dev shell [❄ $DEV_SHELL_NAME]  –  pythia · fastjet · fastjet-contrib · lhapdf · root"
    echo "  make <name>   compile <name>.cc in the current directory"
  '';
}
