{ pkgs }:
(import ./alidist-helpers.nix {
  inherit pkgs;
  stdenv = pkgs.stdenv;
}).o2systemdeps {
  name = "alibuilddeps";
  deps = {
    "openssl*" = pkgs.openssl.dev;
    "xz*"      = pkgs.xz.dev;
    "gettext"  = pkgs.gettext;
    "zlib"     = pkgs.zlib.dev;
  };
}
