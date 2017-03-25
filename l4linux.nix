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
      echo UNPACKING
      tar -C $out -xf $src l4re-snapshot-2016082114/src/l4linux --strip-components=3
      #tar xf $src
      #mkdir -p $out
      #echo MOVING
      #mv l4re-snapshot-*/src/l4linux $out/l4linux
    '';
  };

  #overrideDerivation = pkgs.stdenv.lib.overrideDerivation;
  ##buildLinux0 = pkgs.callPackage "${nixpkgs}/pkgs/os-specific/linux/kernel/manual-config.nix" {};
  ##buildLinuxOverride = args: overrideDerivation (buildLinux0 args)
  #overrideFunctor = functor: overridesFn:
  #  (args: overrideDerivation (functor args) overridesFn);

  kernel = 
    #(import <nixpkgs>/pkgs/os-specific/linux/kernel/generic.nix) (rec {
    #pkgs.callPackage $nixpkgs/pkgs/os-specific/linux/kernel/generic.nix (rec {
    #(import "${nixpkgs}/pkgs/os-specific/linux/kernel/generic.nix") (rec {
    pkgs.callPackage "${nixpkgs}/pkgs/os-specific/linux/kernel/generic.nix" (rec {
      version = "4.7";  # TODO(akavel): ok or not?
      src = l4re;
      #src = fetchurl {
      #  # see: http://os.inf.tu-dresden.de/L4Re/download.html
      #  # FIXME(akavel): use SVN; snapshot may become stale
      #  url = http://os.inf.tu-dresden.de/download/snapshots/l4re-snapshot-2016082114.tar.xz;
      #  sha256 = "d6272a6b07f73d29598b45a82e2dbb44bdac2d5ffcc3e6becd51db669b196c69";
      #};
      kernelPatches = [];
      #postPatch = ''
      #  patchShebangs .
      #  sed -i "s#/bin/pwd#$coreutils/bin/pwd#" \
      #    $(grep -r -l /bin/pwd .)
      #'';
      #buildLinux = overrideDerivation pkgs.buildLinux (oldAttrs: {
      #buildLinux = pkgs.buildLinux.overrideDerivation (oldAttrs: {
      #buildLinux = overrideDerivation buildLinux0 (oldAttrs: {
      #buildLinux = overrideFunctor pkgs.buildLinux (oldAttrs: {
      #  postUnpack = "sourceRoot=$sourceRoot/src/l4linux; echo MCDBG $sourceRoot";
      #});
    });
  #kernel = overrideDerivation kernelRaw (oldArgs : {
  #  postUnpack = "sourceRoot=$sourceRoot/src/l4linux; echo MCDBG $sourceRoot";
  #});

  ## workaround based on info in nixkpgs issues #18895, #18995
  #hardeningDisable = [ "stackprotector" "pic" ];

  # TODO: L4_OBJ_TREE=$out/obj/
  # TODO: (L4_ARCH_X86)
  # TODO: (L4_DEBUG)
  # TODO: 64BIT=y


  ## FIXME(akavel): why $coreutils is not available when listing them just in buildInputs?
  #inherit coreutils;
  #buildInputs = [
  #  perl pkgconfig which
  #  ncurses   # provides: tput
  #  #coreutils # pwd
  #  gcc_multi
  #];
in
  kernel
#  { l4re = l4re; l4linux = kernel; }

