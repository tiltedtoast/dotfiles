{ pkgs, currentUsername, ... }:
{

  networking.wireguard.interfaces.wg0 = {
    privateKeyFile = "/home/${currentUsername}/.config/wireguard/privatekey";
    ips = [ "10.14.0.2/16" ];

    allowedIPsAsRoutes = false;

    peers = [
      {
        publicKey = "fJDA+OA6jzQxfRcoHfC27xz7m3C8/590fRjpntzSpGo=";
        endpoint = "de-fra.prod.surfshark.com:51820";

        allowedIPs = [
          "0.0.0.0/0"
          "::/0"
        ];
      }
    ];
  };

  services.qbittorrent = {
    enable = true;
    webuiPort = 8080;
    openFirewall = true;
    serverConfig = {
      Preferences = {
        Connection = {
          Interface = "wg0";
          InterfaceAddress = "10.14.0.2";
        };
        WebUI = {
          Address = "*";
          LocalHostAuth = false;
          Username = "admin";
          Password_PBKDF2 = "@ByteArray(ld9tpxX1BfxpzgEImGXLJA==:yxC2mw6+EfF14jJNV9ppuS0sqNas7ENWXAccUu+gCVNP0h7NokJA1dgnkoWejmDfp5mq6OEFXEHPGkLJNUZNiw==)";
        };
      };
      LegalNotice.Accepted = true;
    };
  };

  systemd.services.qbittorrent = {
    after = [
      "network-online.target"
      "wireguard-wg0.service"
    ];
    wants = [ "wireguard-wg0.service" ];

    serviceConfig = {
      BindToDevice = "wg0";
    };
  };

  networking.firewall = {
    allowedUDPPorts = [ 51820 ];
    allowedTCPPorts = [ 8080 ];
    checkReversePath = "loose";
  };

  environment.systemPackages = [
    pkgs.wireguard-tools
  ];
}
