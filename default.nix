{ pkgs ? (import <nixpkgs> {})
}:

with pkgs;
{
  resolutionizer = callPackage ./resolutionizer.nix { inherit elixir; inherit (elmPackages) elm-compiler elm-make elm-package; npm = nodePackages.npm; };
}
