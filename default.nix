{ pkgs ? (import <nixpkgs> {})
}:

with pkgs;
{
  server = callPackage ./server { };
  client = callPackage ./client { inherit (elmPackages) elm-compiler elm-make elm-package; npm = nodePackages.npm; };
}
