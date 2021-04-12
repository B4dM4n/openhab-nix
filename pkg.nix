{ stdenv
, fetchurl
, writeShellScript
}:

let
  version = "3.0.1";

  updateScript = fetchurl {
    url = "https://github.com/openhab/openhab-docker/raw/8e1e2767fc36310dbc5ce87db54ac32780cd740a/debian/update";
    sha256 = "PqSn+bTqmOtg6K2BOssDyp05dqmfj15h1j/RqczWTUA=";
  };
in
stdenv.mkDerivation {
  pname = "openhab";
  inherit version;

  src = fetchurl {
    url = "https://bintray.com/openhab/mvn/download_file?file_path=org/openhab/distro/openhab/${version}/openhab-${version}.tar.gz";
    sha256 = "d04513de479fe37eef6afacd8dc8cf4456d9a96a9fa8e4d728047559a184b5d2";
  };

  sourceRoot = ".";

  preUnpack = ''
    mkdir -p $out
    cd $out
  '';

  installPhase = ''
    find \( -name "*.bat" -o -name "*.ps1" -o -name "*.psm1" \) -delete
    
    mkdir $out/dist
    mv $out/conf $out/dist
    mv $out/userdata $out/dist

    sed '/You are already on openHAB/a exit 0' ${updateScript} > $out/runtime/bin/update

    install /dev/stdin $out/runtime/bin/copy-dist <<'EOF'
    #!/bin/sh -eu

    copyFolder() {
      if [ ! -e $1/$2 ]; then
        echo "Copying dist data to $1/$2"
        cp -a -t $1 ${placeholder "out"}/dist/$2
        chmod -R u+w $1/$2
      fi
    }

    copyFolder $1 conf
    copyFolder $1 userdata
    EOF
  '';
}
