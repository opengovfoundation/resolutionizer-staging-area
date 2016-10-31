{ closurecompiler, elm-compiler, elm-make, elm-package, nodejs, npm, stdenv
}:
stdenv.mkDerivation rec {
  name = "resolutionizer-client-${version}";
  version = "0.1.0.0";
  src = ./.;
  buildInputs = [
    closurecompiler elm-compiler elm-make elm-package nodejs npm
  ];

  buildPhase = ''
    HOME=$TMPDIR
    make deps
    make clean
    make build-prod
  '';

  installPhase = ''
    make install DESTDIR=$out
  '';

  meta = {
    license = stdenv.lib.licenses.agpl3;
  };
}
