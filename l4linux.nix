#{ stdenv, fetchurl }:      # nixpkgs .nix
with import <nixpkgs> {};  # standalone .nix

# INFO: run with `nix-build $FILE.nix`
# INFO: for easier debugging, `nix-build -K $FILE.nix` - this keeps failed results in /tmp/nix-...
#  - see Nix manual 14.4.1

# TODO(akavel): try splitting below into src-only derivation + numerous binary derivations
#  OR nicer generation of builds from SVN

# NOTE(akavel): about <nixpkgs> see http://lethalman.blogspot.com/2014/09/nix-pill-15-nix-search-paths.html

let
  # from `with import <nixpkgs> {};`
  nixpkgs = path;

  l4re = stdenv.mkDerivation {
    name = "l4re-snapshot-2016082114";
    src = fetchurl {
      # see: http://os.inf.tu-dresden.de/L4Re/download.html
      # FIXME(akavel): use SVN; snapshot may become stale
      url = http://os.inf.tu-dresden.de/download/snapshots/l4re-snapshot-2016082114.tar.xz;
      sha256 = "d6272a6b07f73d29598b45a82e2dbb44bdac2d5ffcc3e6becd51db669b196c69";
    };
    builder = builtins.toFile "builder.sh" ''
      source $stdenv/setup
      mkdir -p $out
      echo unpacking...
      tar -C $out -xf $src l4re-snapshot-2016082114/src/l4linux --strip-components=3
    '';
  };

  kernel = 
    pkgs.callPackage "${nixpkgs}/pkgs/os-specific/linux/kernel/generic.nix" (rec {
      version = "4.7.0-l4-2016082114";  # TODO(akavel): ok or not?
      modDirVersion = "4.7.0-l4";  # see: nixpkgs issue #17801 and linux-mptcp.nix
      src = l4re;
      kernelPatches = [];
    });
in
  kernel

