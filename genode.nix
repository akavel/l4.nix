#{ stdenv, fetchurl }:      # nixpkgs .nix
with import <nixpkgs> {};  # standalone .nix

# INFO: run with `nix-build $FILE.nix`
# INFO: for easier debugging, `nix-build -K $FILE.nix` - this keeps failed results in /tmp/nix-...
#  - see Nix manual 14.4.1

let
  # TODO(akavel): add option to build from source instead
  genode-toolchain-bin = stdenv.mkDerivation rec {
    name = "genode-toolchain-16.05-x86_64-bin";
    src = fetchurl {
      url = mirror://sourceforge/genode/genode-toolchain/16.05/genode-toolchain-16.05-x86_64.tar.bz2;
      sha256 = "07k41p2ssr6vq793g766y5ng14ljx9x5d5qy2zvjkq7csqr9hr1j";
    };
    builder = builtins.toFile "builder.sh" ''
      source $stdenv/setup

      echo unpacking...
      mkdir -p $out
      tar -C $out -xf $src /usr/local/genode-gcc --strip-components=4

      echo fixup...
      fixupPhase
    '';
  };
in
  genode-toolchain-bin
