#!/usr/bin/env nix-shell
#! nix-shell shell-sile-math.nix --show-trace
# TODO(akavel): do we really have to use above shenaningan line?

with import <nixpkgs> {};

let
  env = stdenv.mkDerivation {
    name = "sile-math-env";
    buildInputs = [
      npm2nix
      nodePackages.node2nix   # https://github.com/svanderburg/node2nix
      castl_amalgm
      #castl_src castl_npm
      lua5_2 lrexlib_pcre
    ];
    #inherit js2lua;
    inherit castl_amalgm;
    #inherit castl_src;
    #inherit castl_npm;
    inherit lrexlib_pcre;
  };
  castl_amalgm = stdenv.mkDerivation rec {
    name = "castl_amalgm-${version}";
    version = "1.2.4";
    src = fetchFromGitHub {
      owner = "PaulBernier"; repo = "castl"; rev = "${version}";
      sha256 = "071nqaapb3lx55bj6xqan24yxa977na8m4a4i3jcidsm8hfziv2p";
    };
    buildPhase = ''
      # TODO(akavel): are below paths incorrect?
      export NPM_CONFIG_PREFIX=$out
      #export NPM_CONFIG_CACHE=$out/fake-cache
      # TODO(akavel): is below path ok, or too much out of the blue?
      export NPM_CONFIG_CACHE=$out/lib/node_modules
      # TODO(akavel): what with below lines, do we need them or not?
      #export NPM_CONFIG_INIT_MODULE=$out/fake-init-module
      #export NPM_CONFIG_USERCONFIG=$out/fake-userconfig
      #export HOME=$out/fake-home

      #export NPM_CONFIG_CACHE=/tmp/.cache
      #export NPM_CONFIG_INIT_MODULE=/tmp/.init.module
      #export NPM_CONFIG_USERCONFIG=/tmp/.userconfig
      #export HOME=/tmp/.fake.home
      npm install -g
      #npm link
    '';
    buildInputs = [ nodejs makeWrapper ];
    dontInstall = true;
    installPhase = ''
      ##mkdir -p $out/lib
      ##cp -r node_modules $out/lib/node_modules
      #mkdir -p $out
      #cp -r node_modules $out/node_modules
      #mkdir -p $out/bin
      #ln -s -r $out/node_modules/.bin/castl $out/bin/
      ##cp bin/castl.js $out/bin/castl
      #wrapProgram $out/bin/castl \
      #  --set NPM_CONFIG_PREFIX $out
    '';
  };
  castl_src = fetchFromGitHub {
    owner = "PaulBernier"; repo = "castl"; rev = "1.2.4";
    sha256 = "071nqaapb3lx55bj6xqan24yxa977na8m4a4i3jcidsm8hfziv2p";
  };
  castl_npm = (callPackage ./tmp2/default.nix {
    castl = { outPath = "${castl_src}"; name = "castl"; };
  }).build;

  #nixfromnpm = callPackage ./nixfromnpm {};
  #nixfromnpm = fetchFromGitHub {
  #  owner = "adnelson"; repo = "nixfromnpm"; rev = "0.11.2";
  #  sha256 = "1ikrnqdjil72i4w3gj4xdm1vsw5p0zjwwa3p9g23lbag26x0rz7n";
  #};

  # SILE uses Lua 5.2 in Nixpkgs
  luaPackages = lua52Packages;
  lrexlib_pcre = luaPackages.buildLuaPackage rec {
    name = "lrexlib-pcre-${version}";
    version = "2.8.0";
    src = fetchFromGitHub {
      owner = "rrthomas"; repo = "lrexlib"; rev = "rel-2-8-0";
      sha256 = "1c62ny41b1ih6iddw5qn81gr6dqwfffzdp7q6m8x09zzcdz78zhr";
    };
    buildInputs = [ luaPackages.luastdlib pcre luarocks ];
    inherit (luaPackages) luastdlib;
    # TODO(akavel): below paths should be auto-detected by Nix wrappers for `lua` and `luarocks`
    # TODO(akavel): same for PCRE_DIR etc.
    LUA_PATH = "${luastdlib}/share/lua/${lua.luaversion}/?.lua;${luastdlib}/share/lua/${lua.luaversion}/?/init.lua";
    configurePhase = ''
      lua mkrockspecs.lua lrexlib ${version}
    '';
    buildPhase = ''
      #luarocks --tree=$out/share/lua \
      luarocks --tree=$out \
        make ${name}-1.rockspec \
        PCRE_DIR=${pcre.dev} \
        PCRE_LIBDIR=${pcre.out}/lib
    '';
    dontInstall = true;
  };
in env

#curl -L https://github.com/khan/katex/releases/download/v0.7.1/katex.tar.gz -o katex-0.7.1.tgz
#tar xvf katex-0.7.1.tgz
#cd katex
#castl katex.js -o --debug

# SILE uses Lua 5.2 in Nixpkgs

#LUA_PATH="$luastdlib/share/lua/5.2/?.lua;$luastdlib/share/lua/5.2/?/init.lua" lua mkrockspecs.lua ~/lrex/lrexlib 2.8.0

# luarocks:
#  --local | --tree=<tree>

