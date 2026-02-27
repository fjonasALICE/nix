# NNLOJET — parton-level event generator for jet cross sections at NNLO QCD accuracy.
# Installation instructions: https://nnlojet.hepforge.org/manual.html (manual §3.1–3.2).
# Requirements (manual §3.1): CMake (>= 3.18), Fortran/C/C++ compilers, Python 3 (>= 3.10), LHAPDF 6.
#
# Optional (manual §3.2): OPENMP, PineAPPL, APPLFAST. Enable by passing:
#   nnlojet.override { enableOpenMP = true; pineappl = pkgs.pineappl; applfast = pkgs.applfast; }
# (pineappl/applfast may not be in nixpkgs; build with OFF if not provided.)
#
# DOKAN (default ON): install the "dokan" (土管) Python workflow — creates a venv, installs the
# bundled dokan package, and installs the nnlojet-run script into bin. DOKAN=OFF skips that.

{ lib
, stdenv
, fetchurl
, cmake
, gfortran
, lhapdf
, makeWrapper
, python3
, enableOpenMP ? true
, pineappl ? null
, applfast ? null
}:

stdenv.mkDerivation rec {
  pname = "nnlojet";
  version = "1.0.2";

  src = fetchurl {
    url = "https://nnlojet.hepforge.org/nnlojet-v${version}.tar.gz";
    hash = "sha256-kI6gmowqMPA5ldgnmidOU1gz4rREdr5956ubV2KChoE=";
  };

  nativeBuildInputs = [ cmake gfortran makeWrapper python3 ];
  buildInputs = [ lhapdf ]
    ++ lib.optional (pineappl != null) pineappl
    ++ lib.optional (applfast != null) applfast;

  # Use unwrapped gfortran so the Nix cc-wrapper does not inject C-only flags
  # (e.g. -fmacro-prefix-map) that cause "valid for C/C++ but not for Fortran" warnings.
  NIX_FFLAGS_COMPILE = "";

  # CMake options per manual §3.2: install prefix, build type, LHAPDF path, Python path.
  # Optional: OPENMP (manual), PineAPPL, APPLFAST — enable via override or pass deps.
  cmakePrefixPath = lib.concatStringsSep ";" ([ lhapdf ]
    ++ lib.optional (pineappl != null) pineappl
    ++ lib.optional (applfast != null) applfast);
  cmakeFlags = [
    "-DCMAKE_INSTALL_PREFIX=${placeholder "out"}"
    "-DCMAKE_BUILD_TYPE=Release"
    "-DLHAPDF_ROOT_DIR=${lhapdf}"
    "-DCMAKE_PREFIX_PATH=${cmakePrefixPath}"
    "-DCMAKE_Fortran_COMPILER=${gfortran.cc}/bin/gfortran"
    "-DCMAKE_Fortran_FLAGS="
    "-DPython3_ROOT_DIR=${python3}"
    "-DPython3_EXECUTABLE=${python3}/bin/python"
    "-DDOKAN=ON"
  ] ++ lib.optional enableOpenMP "-DOPENMP=ON"
    ++ lib.optional (pineappl != null) "-DPINEPPAL=ON"
    ++ lib.optional (applfast != null) "-DAPPLFAST=ON";
  preConfigure = ''
    mkdir -p build
    cd build
  '';
  configurePhase = ''
    runHook preConfigure
    cmake .. $cmakeFlags
    runHook postConfigure
  '';
  buildPhase = ''
    runHook preBuild
    cmake --build . --parallel ''${NIX_BUILD_CORES:-1}
    runHook postBuild
  '';
  installPhase = ''
    runHook preInstall
    cmake --install .
    runHook postInstall
  '';

  # Optional: make binaries find LHAPDF (and optional PineAPPL/APPLFAST) libs at runtime on macOS.
  libPath = lib.makeLibraryPath ([ lhapdf ]
    ++ lib.optional (pineappl != null) pineappl
    ++ lib.optional (applfast != null) applfast);
  postInstall = lib.optionalString stdenv.isDarwin ''
    for prog in "$out/bin/"*; do
      [ -f "$prog" ] && [ -x "$prog" ] || continue
      wrapProgram "$prog" --prefix DYLD_LIBRARY_PATH : "${libPath}"
    done
  '';

  meta = with lib; {
    description = "Parton-level event generator for jet cross sections at NNLO QCD accuracy";
    homepage = "https://nnlojet.hepforge.org/";
    license = licenses.gpl3Only;
    maintainers = [ ];
    platforms = platforms.unix;
  };
}
