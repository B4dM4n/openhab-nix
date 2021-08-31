{ self }:
{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.services.openhab;

  environment = {
    OPENHAB_HOME = "${cfg.package}";
    OPENHAB_CONF = "/var/lib/openhab/conf";
    OPENHAB_RUNTIME = "${cfg.package}/runtime";
    OPENHAB_USERDATA = "/var/lib/openhab/userdata";
    OPENHAB_LOGDIR = "/var/lib/openhab/logs";
    OPENHAB_BACKUPS = "/var/lib/openhab/backups";
    OPENHAB_VERSION = "${cfg.package.version}";
    JAVA_HOME = "${cfg.javaPackage}";
  };

  cliPackage = pkgs.callPackage ./cli.nix {
    inherit environment;
  };

  finalPackage =
    if cfg.withAddons == null
    then cfg.package
    else cfg.package.override { inherit (cfg) withAddons; };
in
{
  options = {
    services.openhab = with types; {
      enable = mkEnableOption "openHAB";

      package = mkOption {
        default = self.packages.${pkgs.stdenv.hostPlatform.system}.openhab;
        defaultText = "self.packages.\${pkgs.stdenv.hostPlatform.system}.openhab";
        description = "openHAB package to use.";
        type = package;
      };

      javaPackage = mkOption {
        default = pkgs.openjdk11;
        defaultText = "pkgs.openjdk11";
        description = "JAVA package to use.";
        type = package;
      };

      withAddons = mkOption {
        type = nullOr bool;
        default = null;
        description = ''
          Configure the addon inclusion for the openhab package. When `null` (default) use the
          package default, otherwise override the `withAddons` package argument.
        '';
      };

      user = mkOption {
        type = str;
        default = "openhab";
        description = ''
          User the openhab daemon should execute under.
        '';
      };

      group = mkOption {
        type = str;
        default = "openhab";
        description = ''
          Group the openhab daemon should execute under.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      cliPackage
    ];

    systemd.services.openhab = {
      path = [
        cfg.javaPackage
        pkgs.gawk
        pkgs.procps
      ];

      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];

      serviceConfig = {
        User = cfg.user;
        Group = cfg.group;

        ExecStartPre = [
          "${finalPackage}/runtime/bin/copy-dist /var/lib/openhab"
          "!${finalPackage}/runtime/bin/update"
        ];
        ExecStart = [ "${finalPackage}/runtime/bin/karaf \${OPENHAB_STARTMODE}" ];
        ExecStop = [ "${finalPackage}/runtime/bin/karaf stop" ];

        Environment = mapAttrsToList (n: v: "${n}=${v}") environment ++ [
          "OPENHAB_STARTMODE=daemon"
        ];
        StateDirectory = "openhab";

        SuccessExitStatus = "0 143";
        RestartSec = 60;
        StartLimitIntervalSec = 600;
        StartLimitBurst = 3;
        Restart = "on-failure";
        TimeoutStopSec = 120;
        LimitNOFILE = 102642;
      };
    };

    users.users = optionalAttrs (cfg.user == "openhab") {
      openhab = {
        group = cfg.group;
        home = "/var/lib/openhab";
        isSystemUser = true;
        description = "Daemon user for the openhab service";
      };
    };

    users.groups = optionalAttrs (cfg.group == "openhab") {
      openhab = { };
    };
  };
}
