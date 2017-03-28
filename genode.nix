#{ stdenv, fetchurl }:      # nixpkgs .nix
with import <nixpkgs> {};  # standalone .nix

# INFO: run with `nix-build $FILE.nix`
# INFO: for easier debugging, `nix-build -K $FILE.nix` - this keeps failed results in /tmp/nix-...
#  - see Nix manual 14.4.1

let
  # from `with import <nixpkgs> {};`
  nixpkgs = path;

  # TODO(akavel): add option to build from source instead
  # TODO(akavel): should we use stdenv.wrapCC or something to wrap the unpacked gcc compilers?
  genode-toolchain-bin = stdenv.mkDerivation {
    name = "genode-toolchain-16.05-x86_64-bin";
    src = fetchurl {
      url = mirror://sourceforge/genode/genode-toolchain/16.05/genode-toolchain-16.05-x86_64.tar.bz2;
      sha256 = "07k41p2ssr6vq793g766y5ng14ljx9x5d5qy2zvjkq7csqr9hr1j";
    };
    # NOTE(akavel): patchelf based on http://sandervanderburg.blogspot.com/2015/10/deploying-prebuilt-binary-software-with.html and grepping patchelf in nixpkgs
    #  and initially through http://unix.stackexchnage.com/a/91578/11352
    # TODO(akavel): isn't below patchelf expected to run automatically in fixupPhase?
    # TODO(akavel): do we also need to patchelf more binaries in this package?
    builder = builtins.toFile "builder.sh" ''
      source $stdenv/setup

      echo unpacking...
      mkdir -p $out
      tar -C $out -xf $src /usr/local/genode-gcc --strip-components=3

      echo fixup...
      fixupPhase
    '';
    # NOTE(akavel): couldn't use makeLibraryPath in toFile because of error:
    #  "in 'toFile': the file 'builder.sh' cannot refer to derivation outputs"
    postFixup = ''
      for f in $(find $out -type f -executable); do
        patchelf \
          --set-interpreter $(cat $NIX_CC/nix-support/dynamic-linker) \
          --set-rpath ${stdenv.lib.makeLibraryPath [ zlib ]} \
          $f \
          || echo "$f: patchelf failed, skipping"
      done

      # TODO(akavel): or should we run this before fixupPhase?
      # TODO(akavel): wrap also other executables? esp. gcc/g++/... ones?
      for prog in x86-g++ x86-gcc; do
        wrapProgram $out/bin/genode-$prog \
          --add-flags \$NIX_CFLAGS_COMPILE
      done
    '';
    buildInputs = [ makeWrapper ];
  };

  ## TODO(akavel): doesn't work
  #cc-wrapper = "${nixpkgs}/pkgs/build-support/cc-wrapper/cc-wrapper.sh";
  #ccWrapperFun = callPackage "${nixpkgs}/pkgs/build-support/cc-wrapper";
  #genode-toolchain-wrap = wrapCCWith ccWrapperFun stdenv.cc.libc ''
  #  wrap genode-x86-g++ ${cc-wrapper} $ccPath/genode-x86-g++
  #'' genode-toolchain-bin;

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
      #sed -i "s#/usr/local/genode-gcc#${genode-toolchain-bin}#" \
      #  tool/create_uboot \
      #  repos/base/etc/tools.conf
    '';
    configurePhase = ''
      tool/create_builddir linux BUILD_DIR=$out
      mkdir -p $out/etc
      echo "CROSS_DEV_PREFIX = ${genode-toolchain-bin}/bin/genode-x86-" > $out/etc/tools.conf
    '';
    buildPhase = ''
      cd $out
      make
    '';
    buildInputs = [
      genode-toolchain-bin which
      # Libs. TODO(akavel): find out which are needed for which apps
      linuxHeaders glibc alsaLib.dev
    ];
  };
in {
  toolchain = genode-toolchain-bin;
  genode = genode;
  #wrap = genode-toolchain-wrap;
}
