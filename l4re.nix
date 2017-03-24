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

  postPatch = ''
    patchShebangs .
    echo "PWD: $coreutils/bin/pwd"
    which pwd
    sed -i "s#/bin/pwd#$coreutils/bin/pwd#" \
      src/l4/tool/kconfig/Makefile \
      src/kernel/fiasco/tool/kconfig/Makefile
  '';

  # TODO(akavel): below seems to have kinda similar result to `make B=something`, but I can't
  # put my finger on what's the exact difference, so that we could build straight into $out
  configurePhase = ''
    # based on src/l4/Makefile's all:: rule, but changed from default x86 to amd64
    #mkdir -C src/l4 check_build_tools
    mkdir -p $out/l4
    cp src/l4/mk/defconfig/config.amd64 $out/l4/.kconfig
    make -C src/l4 O=$out/l4 olddefconfig
  '';
  #configurePhase = ''
  #  # Simulate `make setup` but without interactve input
  #  ## First, simulate `bin/setup.d/04-setup config`
  #  mkdir -p obj
  #  echo 'CONF_DO_AMD64=1' >> obj/.config
  #  ## Now, simulate the rest of `make setup`
  #  pwd
  #  ./bin/setup.d/04-setup setup
  #'';

  # TODO(akavel): make sure we build for x86 / x64 / whatever we need
  # (should be configurable via Nix, with host arch autoconfigured by default on NixOS)
  # see: http://os.inf.tu-dresden.de/L4Re/build.html
  # TODO(akavel): try plugging in into generic buildPhase if possible
  buildPhase = ''
    # TODO(akavel): what's V=0 for? do we need it or not?
    make -C $out/l4 V=0
  '';
  #buildPhase = ''
  #  cd src/l4

  #  # TODO(akavel): try to fix below to use `make B=something` and `make O=something` properly
  #  make O=../../obj/l4/amd64

  #  #make B=$out
  #  #make O=$out config
  #  #make O=$out
  #'';
#  builder = builtins.toFile "builder.sh" ''
#    source $stdenv/setup
#
#    PATH=$perl/bin:$pkg_config/bin:$tput/bin:$which/bin:$PATH
#    which perl
#    which pkg-config
#    which tput
#
#    tar xJf $src
#    cd l4re-core-*/src/l4
#    make B=$out
#    make O=$out config
#    make O=$out
#  '';

  # FIXME(akavel): below apps may be just build dependencies, not runtime ones
  #inherit perl pkg_config tput which;
  inherit coreutils;  # why $coreutils is not available when listing them just in buildInputs?
  buildInputs = [
    perl pkgconfig which
    ncurses   # provides: tput
    #coreutils # pwd
  ];
}
