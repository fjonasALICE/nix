# Custom Nix packages

Packages not (yet) in nixpkgs, built and exposed via the overlay in `../darwin.nix`.

- **nnlojet** — Parton-level event generator for jet cross sections at NNLO QCD.  
  [Manual (install §3.1–3.2)](https://nnlojet.hepforge.org/manual.html).  
  Build requirements (provided by Nix): CMake (≥ 3.18), Fortran/C/C++ compiler, Python 3 (≥ 3.10), LHAPDF 6.  
  No need for a local Homebrew CMake; the derivation uses Nix’s `cmake` and `pkgs.lhapdf`.
