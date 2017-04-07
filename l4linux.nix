#{ stdenv, fetchurl }:      # nixpkgs .nix
#with import <nixpkgs> {};  # standalone .nix
with import <nixpkgs> {
  # Based on https://nixos.org/wiki/CrossCompiling + a bit of https://nixos.org/nixpkgs/manual
  crossSystem = {
    # FIXME: which of below attrs we really need?
    # FIXME: which of below attrs triggers cross-compilation? (appearance of .crossDrv in derivation)
    config = "l4-unknown-linux";
    arch = "x86_64";
    libc = "glibc";
    gcc = {
      arch = "x86_64";
    };
    platform = {
      kernelArch = "l4";
      kernelMajor = "2.6"; # Seems to be magic number required for cross-compiling for Linux 2.6+
                           # See also: https://sourceware.org/ml/crossgcc/2005-12/msg00116.html
      # FIXME: from pkgs/top-level/platforms.nix pcBase
      name = "pc";
      uboot = null;
      kernelHeadersBaseConfig = "defconfig";
      kernelBaseConfig = "defconfig";
      # Build whatever possible as a module, if not stated in the extra config.
      kernelAutoModules = true;
      kernelTarget = "bzImage";
    };
    # FIXME: are below values ok? and do we really require them?
    withTLS = true;
    openssl.system = "linux-generic32";
  };
};

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
    pkgs.callPackage ./kernel-generic-fixed.nix (rec {
      inherit nixpkgs;
      version = "4.7.0-l4-2016082114";  # TODO(akavel): ok or not?
      modDirVersion = "4.7.0-l4";  # see: nixpkgs issue #17801 and linux-mptcp.nix
      src = l4re;
      kernelPatches = [];
    });
in
  # NOTE(akavel): removed .crossDrv per https://github.com/NixOS/nixpkgs/issues/24388
  kernel

