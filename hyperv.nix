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
    inherit (kernel) src;
    patches = kernel.patches ++ [
      #./tools-hv-4.4-4.7.patch
      ./tools-hv-4.7-4.10.patch
    ];
    # FIXME(akavel): workaround for error fixed in 4.10
    hardeningDisable = [ "fortify "];
    preConfigure = ''
      cd tools/hv
    '';
    installPhase = ''
      mkdir -p $out
      for f in lsvmbus $(find . -type f -executable); do
        mv $f $out
      done
    '';
  };
in {
  hv_daemons = hv_daemons;
}


