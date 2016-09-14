{ pkgs ? (import <nixpkgs> {})
, noDevTools ? false
}:

with pkgs;
let
  resolutionizer = callPackage ./. { inherit elixir; inherit (elmPackages) elm-compiler elm-make elm-package; npm = nodePackages.npm; };
  resolutionizerWithDevTools = resolutionizer.overrideDerivation (oldAttrs: {
    buildInputs = oldAttrs.buildInputs ++ [ elmPackages.elm-format elmPackages.elm-reactor elmPackages.elm-repl ];
  });
  package = if noDevTools then resolutionizer else resolutionizerWithDevTools;
in
  package
