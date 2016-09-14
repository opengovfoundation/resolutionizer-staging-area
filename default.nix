{ elixir, elm-compiler, elm-make, elm-package, npm, stdenv
}:
stdenv.mkDerivation rec {
  name = "resolutionizer-${version}";
  version = "0.1.0.0";
  src = ./.;
  buildInputs = [
    elixir elm-compiler elm-make elm-package npm
  ];
  meta = {
    license = stdenv.lib.licenses.agpl3;
  };
}
