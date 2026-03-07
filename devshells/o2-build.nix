{ pkgs }:
# Dev shell providing all system dependencies required by aliBuild to build
# O2/O2Physics, equivalent to the alisw/system-deps/o2-full-deps Homebrew formula
# but sourced entirely from Nix.
#
# Usage:
#   nix develop ~/nix#o2-build
#   aliBuild build O2Physics --defaults o2
let
  helpers = import ../custompackages/alibuildtools/alidist-helpers.nix {
    inherit pkgs;
    stdenv = pkgs.stdenv;
  };

  # Python with pip so alidist's system-check passes.
  python = pkgs.python313.withPackages (p: [ p.pip p.setuptools p.wheel ]);

  # Fake `brew --prefix <pkg>` that returns Nix store paths.
  # Intercepts every `brew --prefix X` call from alidist recipes,
  # pointing them at Nix-managed libraries instead of Homebrew.
  brewDeps = helpers.o2systemdeps {
    name = "o2-brew-deps";
    deps = {
      "openssl*"      = pkgs.openssl.dev;
      "xz*"           = pkgs.xz.dev;
      "zlib*"         = pkgs.zlib.dev;
      "gettext*"      = pkgs.gettext;
      "python*"       = python;
      "gsl*"          = pkgs.gsl;
      "gmp*"          = pkgs.gmp;
      "mpfr*"         = pkgs.mpfr;
      "pcre*"         = pkgs.pcre;
      "freetype*"     = pkgs.freetype;
      "libpng*"       = pkgs.libpng;
      "libxml2*"      = pkgs.libxml2.dev;
      "readline*"     = pkgs.readline;
      "utf8proc*"     = pkgs.utf8proc;
      "zeromq*"       = pkgs.zeromq;
      "libidn2*"      = pkgs.libidn2;
      "msgpack*"      = pkgs.msgpack-cxx;
      "llvm*"         = pkgs.llvmPackages_18.llvm;
      "glfw*"         = pkgs.glfw;
      "libomp*"       = pkgs.llvmPackages_18.openmp;
      "boost*"        = pkgs.boost.dev;
      "libuv*"        = pkgs.libuv;
      "nlohmann-json*" = pkgs.nlohmann_json;
      "re2*"          = pkgs.re2;
      "abseil*"       = pkgs.abseil-cpp;
      "lz4*"          = pkgs.lz4;
      "grpc*"         = pkgs.grpc;
      "tbb*"          = pkgs.tbb;
      "hdf5*"         = pkgs.hdf5;
      "xerces-c*"     = pkgs.xercesc;
    };
  };
in
pkgs.mkShell {
  packages = [
    brewDeps

    # aliBuild itself (with all Python deps bundled)
    pkgs.alibuild

    # Build toolchain
    pkgs.autoconf
    pkgs.automake
    pkgs.libtool
    pkgs.pkg-config
    pkgs.cmake
    pkgs.ninja
    pkgs.m4
    pkgs.perl
    pkgs.texinfo
    pkgs.gnumake
    pkgs.coreutils
    pkgs.pigz
    pkgs.git
    pkgs.rsync
    pkgs.gtk-doc

    # Compilers (gcc for Fortran, LLVM 18 for clang as required by O2)
    pkgs.gfortran
    pkgs.llvmPackages_18.clang
    pkgs.llvmPackages_18.llvm
    pkgs.llvmPackages_18.openmp

    # Libraries (headers on include path, bins on PATH)
    pkgs.openssl.dev
    pkgs.xz.dev
    pkgs.zlib.dev
    pkgs.gettext
    python
    pkgs.gsl
    pkgs.gmp
    pkgs.mpfr
    pkgs.isl
    pkgs.libmpc
    pkgs.pcre
    pkgs.freetype
    pkgs.libpng
    pkgs.libxml2.dev
    pkgs.readline
    pkgs.utf8proc
    pkgs.zeromq
    pkgs.libidn2
    pkgs.msgpack-cxx
    pkgs.glfw
    pkgs.boost.dev
    pkgs.libuv
    pkgs.nlohmann_json
    pkgs.re2
    pkgs.abseil-cpp
    pkgs.lz4
    pkgs.grpc
    pkgs.tbb
    pkgs.hdf5
    pkgs.xercesc
    pkgs.sqlite
    pkgs.cacert
    pkgs.apple-sdk_15
  ];

  shellHook = ''
    export DEV_SHELL_NAME="o2-build"
    export ALIBUILD_WORK_DIR="''${ALIBUILD_WORK_DIR:-$HOME/alice/sw}"
    # Point git/curl at Nix's CA bundle so HTTPS fetches work
    export GIT_SSL_CAINFO="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
    export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
    # Ensure our fake brew is found before Homebrew's real brew
    echo "O2 build shell  [❄ $DEV_SHELL_NAME]"
    echo "  ALIBUILD_WORK_DIR = $ALIBUILD_WORK_DIR"
    echo "  Run: aliBuild build O2Physics --defaults o2 -C ~/alice/alidist"
    if [ -z "''${ZSH_VERSION-}" ] && command -v zsh >/dev/null 2>&1; then
      exec zsh -i
    fi
  '';
}
