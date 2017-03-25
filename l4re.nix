#{ stdenv, fetchurl }:      # nixpkgs .nix
with import <nixpkgs> {};  # standalone .nix

# INFO: run with `nix-build $FILE.nix`
# INFO: for easier debugging, `nix-build -K $FILE.nix` - this keeps failed results in /tmp/nix-...
#  - see Nix manual 14.4.1

# TODO(akavel): try splitting below into src-only derivation + numerous binary derivations
#  OR nicer generation of builds from SVN

stdenv.mkDerivation {
  name = "l4re-core-2016082114";  # TODO(akavel): ok name or fix?
  src = fetchurl {
    # see: http://os.inf.tu-dresden.de/L4Re/download.html
    # FIXME(akavel): use SVN; snapshot may become stale
    url = http://os.inf.tu-dresden.de/download/snapshots/l4re-core-2016082114.tar.xz;
    sha256 = "cd50e7f3c2c0bc7d62db23790f3ad856694defe5b2da8d95ca9f34a051937f88";
  };

  # workaround based on info in nixkpgs issues #18895, #18995
  hardeningDisable = [ "stackprotector" "pic" ];

  postPatch = ''
    patchShebangs .
    sed -i "s#/bin/pwd#$coreutils/bin/pwd#" \
      src/l4/tool/kconfig/Makefile \
      src/kernel/fiasco/tool/kconfig/Makefile
  '';

  outputs = ["out" "fiasco"];

  configurePhase = ''
    # FIASCO
    # based on src/kernel/fiasco/Makefile's all:: rule, but changed from default arch to amd64
    make -C src/kernel/fiasco B=$fiasco
    cp src/kernel/fiasco/src/templates/globalconfig.out.amd64-1 $fiasco/globalconfig.out
    #echo 'CONFIG_AMD64=y' > $fiasco/globalconfig.out  # TODO: above `cp` or just this?
    make -C src/kernel/fiasco O=$fiasco olddefconfig

    # L4RE
    # based on src/l4/Makefile's all:: rule, but changed from default x86 to amd64
    make -C src/l4 check_build_tools
    mkdir -p $out
    cp src/l4/mk/defconfig/config.amd64 $out/.kconfig
    make -C src/l4 O=$out olddefconfig
  '';

  # TODO(akavel): make sure we build for x86 / x64 / whatever we need
  # (should be configurable via Nix, with host arch autoconfigured by default on NixOS)
  # see: http://os.inf.tu-dresden.de/L4Re/build.html
  # TODO(akavel): try plugging in into generic buildPhase if possible
  buildPhase = ''
    # TODO(akavel): what's V=0 for? do we need it or not?
    #make -C $fiasco V=0
    make -C $fiasco
    make -C $out
  '';

  dontInstall = true;

  # FIXME(akavel): why $coreutils is not available when listing them just in buildInputs?
  inherit coreutils;
  buildInputs = [
    perl pkgconfig which
    ncurses   # provides: tput
    #coreutils # pwd
    gcc_multi
  ];
}
