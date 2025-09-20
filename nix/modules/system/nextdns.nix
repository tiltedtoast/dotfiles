{
  config,
  lib,
  ...
}:

with lib;

let
  cfg = config.nextdns;
in
{
  options.nextdns = {
    enable = mkEnableOption "NextDNS CLI config";

    configFile = mkOption {
      type = types.path;
      defaultText = "config.age.secrets.nextdns-config.path";
      description = "Path to NextDNS config file.";
    };
  };

  config = mkIf cfg.enable {

    systemd.services.nextdns-activate = {
      script = ''
        /run/current-system/sw/bin/nextdns activate
      '';
      after = [ "nextdns.service" ];
      wantedBy = [ "multi-user.target" ];
    };

    services.nextdns = {
      enable = true;
      arguments = [
        "-config-file"
        cfg.configFile
      ];
    };
  };
}
