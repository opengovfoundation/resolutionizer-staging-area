{ pkgs ? (import <nixpkgs> {})
, noDevTools ? false
}:

with pkgs;
let
  builds = callPackage ./. { };
  devTools = [ elmPackages.elm-format elmPackages.elm-reactor elmPackages.elm-repl ];
  unifiedEnv = stdenv.mkDerivation {
    name = "resolutionizer";
    buildInputs = if noDevTools then [] else devTools;
    # The `buildInputs` attrs of the derivations are empty at this point, but
    # the derivations needed are stored in the `nativeBuildInputs` attr, this is
    # a hack
    nativeBuildInputs = builds.server.nativeBuildInputs ++ builds.client.nativeBuildInputs ++ builds.bulk-clause-import.env.nativeBuildInputs;
  };
in
  unifiedEnv
