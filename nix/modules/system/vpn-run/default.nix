{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.vpn-run;

  # Read the script and substitute config values
  scriptText =
    builtins.replaceStrings
      [
        "@defaultInterface@"
        "@vethHostAddress@"
        "@vethNsAddress@"
        "@disableIPv6@"
        "@dropNonVpnForward@"
      ]
      [
        cfg.defaultInterface
        cfg.vethHostAddress
        cfg.vethNsAddress
        (if cfg.disableIPv6 then "true" else "false")
        (if cfg.dropNonVpnForward then "true" else "false")
      ]
      (builtins.readFile ./vpn-run.sh);

  vpnRunScript = pkgs.writeShellApplication {
    name = "vpn-run";

    runtimeInputs = [
      pkgs.iproute2
      pkgs.gnugrep
      pkgs.util-linux
      pkgs.procps
      pkgs.netcat
      pkgs.iptables
      pkgs.coreutils
      pkgs.socat
    ];

    text = scriptText;
  };

in
{
  options.vpn-run = {
    enable = mkEnableOption "vpn-run service for routing commands through a specific interface via a veth-isolated namespace";

    defaultInterface = mkOption {
      type = types.str;
      default = "wg0";
      description = "Default network interface to route traffic through";
      example = "wg0";
    };

    allowedUsers = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "List of users allowed to use vpn-run without sudo";
      example = [
        "alice"
        "bob"
      ];
    };

    shellAlias = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to create a shell alias for vpn-run";
    };

    vethHostAddress = mkOption {
      type = types.str;
      default = "198.18.0.1/30";
      description = "Host-side veth address (CIDR). Keep a /30 or /31 to avoid conflicts.";
      example = "198.18.0.1/30";
    };

    vethNsAddress = mkOption {
      type = types.str;
      default = "198.18.0.2/30";
      description = "Namespace-side veth address (CIDR). Must be in the same subnet as vethHostAddress.";
      example = "198.18.0.2/30";
    };

    disableIPv6 = mkOption {
      type = types.bool;
      default = true;
      description = "Disable IPv6 inside the network namespace to avoid leaks.";
    };

    dropNonVpnForward = mkOption {
      type = types.bool;
      default = true;
      description = "Drop forwarding from the namespace to any interface other than the chosen VPN interface.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ vpnRunScript ];

    environment.shellAliases = {
      vpn-run = mkIf cfg.shellAlias "sudo -E vpn-run";
    };

    security.sudo.extraRules = mkIf (cfg.allowedUsers != [ ]) [
      {
        users = cfg.allowedUsers;
        commands = [
          {
            command = "${vpnRunScript}/bin/vpn-run";
            options = [
              "NOPASSWD"
              "SETENV"
            ];
          }
          {
            command = "/run/current-system/sw/bin/vpn-run";
            options = [
              "NOPASSWD"
              "SETENV"
            ];
          }
        ];
      }
    ];

    users.groups.vpn-run = mkIf (cfg.allowedUsers != [ ]) {
      members = cfg.allowedUsers;
    };
  };
}
