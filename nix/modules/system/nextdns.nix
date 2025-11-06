{
  config,
  lib,
  pkgs,
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
      type = types.path;
      description = "Path to the systemd-resolved config file for NextDNS.";
    };

    hostName = mkOption {
      type = types.str;
      defaultText = "NixOS--PC";
      description = "The hostname to use for NextDNS (-- for spaces)";
    };
  };

  config = mkIf cfg.enable {
    networking.networkmanager = {
      dns = "systemd-resolved";
      settings."global-dns-domain-*".servers = "127.0.0.53";
    };

    services.resolved = {
      enable = true;
      extraConfig =
        lib.optionalString (config.services.avahi.enable) ''
          [Resolve]
          MulticastDNS=no
        ''
        + ''
          [Resolve]
          Domains=~.
        '';
    };

    systemd.services.nextdns-config-generator = {
      description = "Generate NextDNS config for systemd-resolved";
      before = [ "systemd-resolved.service" "NetworkManager.service" ];
      wantedBy = [ "multi-user.target" ];
      after = [ "local-fs.target" ];      

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };

      script = ''
        mkdir -p /run/systemd/resolved.conf.d

        ${pkgs.gnused}/bin/sed 's/HOSTNAME/${cfg.hostName}/g' ${cfg.configFile} > /run/systemd/resolved.conf.d/99-nextdns.conf
      '';
    };
  };
}
