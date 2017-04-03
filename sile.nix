with import <nixpkgs> {};

let
  libtexpdf = stdenv.mkDerivation {
    name = "libtexpdf-sile-0.9.4";
    src = fetchFromGitHub {
      owner = "simoncozens";
      repo = "libtexpdf";
      rev = "0cb0c20a3ba40057e6902551300630";
      sha256 = "07xy0mv7xladqynsbh6vadzwxcfkr1q0vajjg3j7gaazainxn0cw";
    };
  };

  sile = stdenv.mkDerivation {
    name = "sile-0.9.4";
    src = fetchFromGitHub {
      owner = "simoncozens";
      repo = "sile";
      rev = "v0.9.4";
      sha256 = "1864c3gdigdcj0r1r32q89k0psiz1xmgfkkf9x6a4mpkavs5p74k";
    };
    #src = fetchurl {
    #  url = https://github.com/simoncozens/sile/archive/v0.9.4.tar.gz;
    #};

    inherit libtexpdf;
  };
in
  sile.libtexpdf
