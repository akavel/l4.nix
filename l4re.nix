#{ stdenv, fetchurl }:      # nixpkgs .nix
with import <nixpkgs> {};  # standalone .nix

# INFO: run with `nix-build $FILE.nix`

stdenv.mkDerivation {
  name = "l4re-0.0.1";  # FIXME(akavel): fix version
  src = fetchurl {
    # see: http://os.inf.tu-dresden.de/L4Re/download.html
    # FIXME(akavel): use SVN; snapshot may become stale
    url = http://os.inf.tu-dresden.de/download/snapshots/l4re-core-2016082114.tar.xz;
    sha256 = "cd50e7f3c2c0bc7d62db23790f3ad856694defe5b2da8d95ca9f34a051937f88";
  };
  # TODO(akavel): make sure we build for x86 / x64 / whatever we need
  # (should be configurable via Nix, with host arch autoconfigured by default on NixOS)
  # see: http://os.inf.tu-dresden.de/L4Re/build.html
  builder = builtins.toFile "builder.sh" ''
    source $stdenv/setup

    tar xJf $src
    cd l4re-core-*/src/l4
    make B=$out
    make O=$out config
    make O=$out
  '';
}
