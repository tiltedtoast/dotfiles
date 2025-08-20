{
  pkgs,
  lib,
  config,
  ...
}:

with lib;

let
  cfg = config.qbittorrent;
in
{
  options.qbittorrent = {
    enable = mkEnableOption "qbittorrent";
    package = lib.mkPackageOption pkgs "qbittorrent-nox" { };

    wireguard = {
      interface = mkOption {
        type = types.str;
        defaultText = "wg0";
        description = "Wireguard interface to use";
      };

      listenPort = mkOption {
        type = types.int;
        default = 51820;
        description = "Wireguard listen port";
      };
    };

    webui = mkOption {
      type = types.submodule {
        options = {
          port = mkOption {
            type = types.int;
            default = 8080;
            description = "WebUI port";
          };
          username = mkOption {
            type = types.str;
            default = "admin";
            description = "Username for the webui";
          };
          hashedPassword = mkOption {
            type = types.str;
            default = "";
            description = "Hashed password for the webui (PBKDF2)";
          };
        };
      };
      description = "WebUI options";
      default = { };
    };
  };

  config = mkIf cfg.enable {
    services.qbittorrent = {
      enable = true;
      package = cfg.package;
      webuiPort = cfg.webui.port;
      openFirewall = true;
      serverConfig = {
        BitTorrent.Session = {
          AddExtensionToIncompleteFiles = true;

          GlobalMaxRatio = 1;
          GlobalMaxSeedingMinutes = 1440;

          MaxConnections = -1;
          MaxConnectionsPerTorrent = -1;
          MaxUploads = -1;
          MaxUploadsPerTorrent = -1;

          Interface = cfg.wireguard.interface;
          InterfaceName = cfg.wireguard.interface;
        };
        Preferences = {
          General = {
            StatusbarExternalIPDisplayed = true;
            Locale = "en";
          };
          Connection = {
            Interface = cfg.wireguard.interface;
          };
          WebUI = with cfg.webui; {
            Address = "*";
            LocalHostAuth = false;
            Username = username;
            Password_PBKDF2 = hashedPassword;
          };
        };
        LegalNotice.Accepted = true;
      };
    };

    systemd.services.qbittorrent = {
      after = [
        "network-online.target"
        "wireguard-${cfg.wireguard.interface}.service"
      ];
      wants = [ "wireguard-${cfg.wireguard.interface}.service" ];
    };

    networking.firewall = {
      allowedUDPPorts = [ cfg.wireguard.listenPort ];
      allowedTCPPorts = [
        cfg.webui.port
        cfg.wireguard.listenPort
      ];
      checkReversePath = "loose";
    };

    environment.systemPackages = [
      pkgs.wireguard-tools
    ];
  };
}
