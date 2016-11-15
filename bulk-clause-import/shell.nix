{ pkgs ? (import <nixpkgs> {})
, haskellPackages ? pkgs.haskell.packages.ghc801
, haskellDevTools ? (if pkgs ? myHaskellDevTools then pkgs.myHaskellDevTools else (p : []))
}:

let
  modifiedHaskellPackages = haskellPackages.override {
    overrides = self: super: {
      resolutionizer-bulk-clause-import = self.callPackage ./. {};
    };
  };

  package = with modifiedHaskellPackages;
    pkgs.haskell.lib.addBuildTools
      resolutionizer-bulk-clause-import
      (haskellDevTools modifiedHaskellPackages);
in
  package.env
