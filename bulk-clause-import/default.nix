{ mkDerivation, aeson, base, bytestring, hspec, hspec-megaparsec
, megaparsec, stdenv
}:
mkDerivation {
  pname = "resolutionizer-bulk-clause-import";
  version = "0.1.0.0";
  src = ./.;
  isLibrary = true;
  isExecutable = true;
  libraryHaskellDepends = [ aeson base megaparsec ];
  executableHaskellDepends = [ aeson base bytestring ];
  testHaskellDepends = [ base hspec hspec-megaparsec megaparsec ];
  license = stdenv.lib.licenses.agpl3;
}
