{ stdenv, fetchurl }:

stdenv.mkDerivation {
  name = "l4re-0.0.1";  # FIXME(akavel): fix version
  src = fetchurl {
    url = http://os.inf.tu-dresden.de/download/snapshots/l4re-core-2016082114.tar.xz;  # FIXME(akavel): use SVN; snapshot may become stale
    sha256 = "1193da7c4838a829db978612323877d4926b9ae21487d3f28b937ef929650faa";
  };
}
