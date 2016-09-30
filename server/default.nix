{ gawk, elixir, makeWrapper, stdenv, wkhtmltopdf
}:
stdenv.mkDerivation rec {
  name = "resolutionizer-server-${version}";
  version = "0.1.0.0";
  src = ./.;
  buildInputs = [
    gawk elixir makeWrapper wkhtmltopdf
  ];

  # Elixir complains otherwise
  # TODO: it is still complaining
  LANG = "en_US.UTF-8";
  LC_CTYPE = "en_US.UTF-8";

  buildPhase = ''
    export HOME=$TMPDIR
    export MIX_ENV=prod
    mix do \
      local.hex --force, \
      local.rebar --force, \
      release --env=prod
  '';

  installPhase = ''
    mkdir -p $out

    tar xvf rel/resolutionizer/releases/0.0.1/resolutionizer.tar.gz -C $out/

    mv $out/bin/resolutionizer $out/bin/resolutionizer-unwrapped
    makeWrapper $out/bin/resolutionizer-unwrapped $out/bin/resolutionizer \
      --set PATH '${stdenv.lib.makeBinPath [ wkhtmltopdf ]}:$PATH'

    sed -i -e "s|awk|${gawk}/bin/awk|" $out/releases/0.0.1/resolutionizer.sh

    mkdir $out/log
  '';

  meta = {
    license = stdenv.lib.licenses.agpl3;
  };
}
