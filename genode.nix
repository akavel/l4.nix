#{ stdenv, fetchurl }:      # nixpkgs .nix
with import <nixpkgs> {};  # standalone .nix

# INFO: run with `nix-build $FILE.nix`
# INFO: for easier debugging, `nix-build -K $FILE.nix` - this keeps failed results in /tmp/nix-...
#  - see Nix manual 14.4.1

let
  # TODO(akavel): add option to build from source instead
  genode-toolchain-bin = stdenv.mkDerivation {
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

  genode = stdenv.mkDerivation {
    name = "genode-17.02";
    src = fetchFromGitHub {
      owner = "genodelabs";
      repo = "genode";
      rev = "17.02";
      sha256 = "1mhik38bcixqnr658diwspic5xx65z3gxlyqwq52ncx1vmi0i7v5";
    };
    postPatch = ''
      patchShebangs .
      #sed -i "s#/usr/local/genode-gcc/bin#${genode-toolchain-bin}#" \
      #  tool/create_uboot \
      #  repos/base/etc/tools.conf
    '';
    configurePhase = ''
      tool/create_builddir linux BUILD_DIR=$out
      mkdir -p $out/etc
      echo "CROSS_DEV_PREFIX = ${genode-toolchain-bin}/genode-x86-" > $out/etc/tools.conf
    '';
    buildPhase = ''
      cd $out
      make
    '';
    buildInputs = [
      genode-toolchain-bin which
    ];
  };
in
  { toolchain = genode-toolchain-bin; genode = genode; }
