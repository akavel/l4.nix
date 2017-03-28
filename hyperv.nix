#{ stdenv, fetchurl }:      # nixpkgs .nix
with import <nixpkgs> {};  # standalone .nix

# INFO: run with `nix-build $FILE.nix`
# INFO: for easier debugging, `nix-build -K $FILE.nix` - this keeps failed results in /tmp/nix-...
#  - see Nix manual 14.4.1

let
  # from `with import <nixpkgs> {};`
  nixpkgs = path;
  kernel = linux;

  # See:
  # - https://github.com/kubernetes/minikube/tree/master/deploy/iso/minikube-iso/package/hv-kvp-daemon
  # - https://github.com/torvalds/linux/tree/master/tools/hv
  # TODO(akavel): find .service files for remaining daemons: hv_fcopy_daemon, hv_vss_daemon

  # Based on <nixpkgs>/pkgs/os-specific/linux/kernel/perf.nix
  hv_daemons = stdenv.mkDerivation {
    name = "hv_daemons-${kernel.version}";
    inherit (kernel) src patches;
    preConfigure = ''
      cd tools/hv
      #sed -i s,/usr/include/elfutils,$elfutils/include/elfutils, Makefile
      export makeFlags="DESTDIR=$out $makeFlags"
    '';
  };
in {
  hv_daemons = hv_daemons;
}


