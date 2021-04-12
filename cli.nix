{ lib
, coreutils
, fetchurl
, gawk
, makeWrapper
, procps
, runCommand
, unzip
, zip
, environment
}:

with lib;
let
  openhab-cli = fetchurl {
    url = "https://github.com/openhab/openhab-linuxpkg/raw/d4020f5870a6cfc0a02ea156ba2ada4cf1add616/resources/usr/bin/openhab-cli";
    sha256 = "Gp1Y9zypz+pLdqWTlyKPk7r2R+t1ZgaCRm3UGVDREZ8=";
    postFetch = ''
      patch $out <${./openhab-cli.patch}
    '';
  };
in
runCommand "openhab-cli"
{
  nativeBuildInputs = [ makeWrapper ];

  meta = {
    description = "Utility script to simplify the use of openHAB";
    homepage = "https://github.com/openhab/openhab-linuxpkg";
    license = licenses.epl20;
  };
} ''
  install -D -m 555 ${openhab-cli} $out/bin/openhab-cli
  wrapProgram $out/bin/openhab-cli \
    ${concatStrings (mapAttrsToList (n: v: ''
      --set ${n} ${v} \
    '') environment)
    } --prefix PATH : "${lib.makeBinPath [ coreutils zip unzip gawk procps ]}"
''
