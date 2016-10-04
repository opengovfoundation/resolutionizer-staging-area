{ elm-compiler, elm-make, elm-package, npm, stdenv
}:
stdenv.mkDerivation rec {
  name = "resolutionizer-client-${version}";
  version = "0.1.0.0";
  src = ./.;
  buildInputs = [
    elm-compiler elm-make elm-package npm
  ];

  buildPhase = ''
    HOME=$TMPDIR
    make deps
    make clean
    make build
  '';

  installPhase = ''
    make install DESTDIR=$out
  '';

  meta = {
    license = stdenv.lib.licenses.agpl3;
  };
}
