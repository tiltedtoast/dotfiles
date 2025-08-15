{
  config,
  lib,
  currentUsername,
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
      defaultText = "/home/${currentUsername}/.config/nextdns/resolved.conf";
      description = "Absolute path to the systemd-resolved config file for NextDNS.";
    };

    hostName = mkOption {
      type = types.str;
      defaultText = "NixOS--PC";
      description = "The hostname to use for NextDNS (-- for spaces)";
    };
  };

  config = mkIf cfg.enable {

    services.resolved = {
      enable = true;

      # TODO: agenix? sops-nix?
      extraConfig = lib.replaceStrings [ "HOSTNAME" ] [ cfg.hostName ] (
        builtins.readFile cfg.configFile
      );
    };

  };
}
