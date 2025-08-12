{
  config,
  pkgs,
  currentUsername,
  lib,
  ...
}:

let
  cfg = config.nextdns;
in
with lib;
{
  options.nextdns = {
    enable = mkEnableOption "nextdns";

    configFile = mkOption {
      type = types.str;
      default = "/home/${currentUsername}/.config/nextdns/nextdns.conf";
      description = "Absolute path to the nextdns config file to use";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.nextdns ];

    services.nextdns = {
      enable = true;
      arguments = [
        "-config-file"
        cfg.configFile
      ];
    };

    systemd.services.nextdns-activate = {
      script = ''
        /run/current-system/sw/bin/nextdns activate
      '';
      after = [ "nextdns.service" ];
      wantedBy = [ "multi-user.target" ];
    };
  };
}
