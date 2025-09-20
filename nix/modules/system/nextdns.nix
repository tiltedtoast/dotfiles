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
    enable = mkEnableOption "NextDNS via systemd-resolved";

    configFile = mkOption {
      type = types.str;
      description = "Absolute path to the systemd-resolved config file for NextDNS.";
    };

    hostName = mkOption {
      type = types.str;
      defaultText = "NixOS--PC";
      description = "The hostname to use for NextDNS (-- for spaces)";
    };
  };

  config = mkIf cfg.enable {
    networking.networkmanager.dns = "systemd-resolved";
    services.resolved = {
      enable = true;
      extraConfig = lib.replaceStrings [ "HOSTNAME" ] [ cfg.hostName ] (builtins.readFile cfg.configFile);
    };

  };
}
