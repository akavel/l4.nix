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
      lua5_2 lrexlib_pcre
    ];
    #inherit js2lua;
    inherit castl_amalgm;
    LUA_PATH = "${castl_amalgm}/lib/node_modules/castl/lua/?.lua";
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
      # TODO(akavel): is below path ok, or too much out of the blue?
      export NPM_CONFIG_CACHE=$out/lib/node_modules
      npm install -g
    '';
    buildInputs = [ nodejs makeWrapper ];
    dontInstall = true;
  };

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

