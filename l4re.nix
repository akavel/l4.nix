#{ stdenv, fetchurl }:      # nixpkgs .nix
with import <nixpkgs> {};  # standalone .nix

# INFO: run with `nix-build $FILE.nix`

stdenv.mkDerivation {
  name = "l4re-0.0.1";  # FIXME(akavel): fix version
  src = fetchurl {
    url = http://os.inf.tu-dresden.de/download/snapshots/l4re-core-2016082114.tar.xz;  # FIXME(akavel): use SVN; snapshot may become stale
    sha256 = "cd50e7f3c2c0bc7d62db23790f3ad856694defe5b2da8d95ca9f34a051937f88";
  };
}
