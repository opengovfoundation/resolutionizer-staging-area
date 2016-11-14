{ pkgs ? (import <nixpkgs> {})
, haskellPackages ? pkgs.haskell.packages.ghc801
}:

with pkgs;
let
  modifiedHaskellPackages = haskellPackages.override {
    overrides = self: super: {
      resolutionizer-bulk-clause-import = self.callPackage ./bulk-clause-import {};
    };
  };
in rec {
  server = callPackage ./server { inherit bulk-clause-import; };
  client = callPackage ./client { inherit (elmPackages) elm-compiler elm-make elm-package; npm = nodePackages.npm; };
  bulk-clause-import = haskell.lib.disableSharedExecutables modifiedHaskellPackages.resolutionizer-bulk-clause-import;
}
