{ gawk, elixir, erlang, makeWrapper, stdenv, which, wkhtmltopdf, imagemagickBig,
  ghostscript, glibcLocales
}:
let
  cleanSource = name: type: let baseName = baseNameOf (toString name); in ! (
    (type == "directory" && baseName == ".git") ||
    (type == "directory" && baseName == "_build") ||
    (type == "directory" && baseName == "static")
  );
in stdenv.mkDerivation rec {
  name = "resolutionizer-server-${version}";
  version = "0.1.0.0";
  src = builtins.filterSource cleanSource ./.;
  buildInputs = [
    elixir makeWrapper wkhtmltopdf pdftk imagemagickBig ghostscript
  ];

  # Need this to support the locale stuff
  LOCALE_ARCHIVE = "${glibcLocales}/lib/locale/locale-archive";
  # Locale stuff, Elixir complains otherwise
  LANG = "en_US.UTF-8";
  LC_ALL = "en_US.UTF-8";

  buildPhase = ''
    export HOME=$TMPDIR
    export MIX_ENV=prod
    mix do \
      local.hex --force, \
      local.rebar --force, \
      deps.get, \
      release --env=prod
  '';

  installPhase = ''
    mkdir -p $out

    tar xvf rel/resolutionizer/releases/0.0.1/resolutionizer.tar.gz -C $out/

    mv $out/bin/resolutionizer $out/bin/resolutionizer-unwrapped
    makeWrapper $out/bin/resolutionizer-unwrapped $out/bin/resolutionizer \
      --set PATH '${stdenv.lib.makeBinPath [ wkhtmltopdf pdftk erlang imagemagickBig ghostscript ]}:$PATH'

    sed -i -e "s|awk|${gawk}/bin/awk|" $out/releases/0.0.1/resolutionizer.sh
    sed -i -e "s|which|${which}/bin/which|" $out/releases/0.0.1/resolutionizer.sh

    mkdir $out/log
  '';

  meta = {
    license = stdenv.lib.licenses.agpl3;
  };
}
