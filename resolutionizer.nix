{ elixir, elm-compiler, elm-make, elm-package, makeWrapper, npm, wkhtmltopdf, stdenv
}:
stdenv.mkDerivation rec {
  name = "resolutionizer-${version}";
  version = "0.1.0.0";
  src = ./.;
  buildInputs = [
    elixir elm-compiler elm-make elm-package makeWrapper npm wkhtmltopdf
  ];

  # Elixir complains otherwise
  # TODO: it is still complaining
  LANG = "en_US.UTF-8";
  LC_CTYPE = "en_US.UTF-8";

  buildPhase = ''
    HOME=$TMPDIR

    pushd .
    cd client
    make deps
    make install
    popd

    MIX_ENV=prod
    pushd .
    cd server
    mix do \
      local.hex --force, \
      local.rebar --force, \
      phoenix.digest \
      release --env=prod
    popd
  '';

  installPhase = ''
    mkdir -p $out

    tar xvf server/rel/resolutionizer/releases/0.0.1/resolutionizer.tar.gz -C $out/

    mv $out/bin/resolutionizer $out/bin/resolutionizer-unwrapped
    makeWrapper $out/bin/resolutionizer-unwrapped $out/bin/resolutionizer \
      --set PATH '${stdenv.lib.makeBinPath [ wkhtmltopdf ]}:$PATH'

    mkdir $out/log
  '';

  meta = {
    license = stdenv.lib.licenses.agpl3;
  };
}
