{ mkDerivation, aeson, base, bytestring, hspec, hspec-megaparsec
, megaparsec, stdenv
}:
let
  cleanSource = name: type: let baseName = baseNameOf (toString name); in ! (
    (type == "directory" && baseName == "dist")
  );
in mkDerivation {
  pname = "resolutionizer-bulk-clause-import";
  version = "0.1.0.0";
  src = builtins.filterSource cleanSource ./.;
  isLibrary = true;
  isExecutable = true;
  libraryHaskellDepends = [ aeson base megaparsec ];
  executableHaskellDepends = [ aeson base bytestring ];
  testHaskellDepends = [ base hspec hspec-megaparsec megaparsec ];
  license = stdenv.lib.licenses.agpl3;
}
