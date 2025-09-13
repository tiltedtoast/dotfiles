{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.vpn-run;

  vpnRunScript = pkgs.writeShellApplication {
    name = "vpn-run";

    runtimeInputs = [
      pkgs.iproute2
      pkgs.gnugrep
      pkgs.gawk
      pkgs.util-linux
    ];

    text = ''
      set -euo pipefail

      INTERFACE="${cfg.defaultInterface}"
      NAMESPACE="vpn-run-ns"
      CLEANUP_ON_EXIT=true
      VERBOSE=false

      usage() {
          echo "Usage: $(basename "$0") [OPTIONS] COMMAND [ARGS...]"
          echo ""
          echo "Run a command in a network namespace with only VPN access"
          echo ""
          echo "Options:"
          echo "  -i, --interface NAME    VPN interface name (default: ${cfg.defaultInterface})"
          echo "  -n, --namespace NAME    Namespace name (default: vpn-run-ns)"
          echo "  -k, --keep-namespace    Don't cleanup namespace on exit"
          echo "  -v, --verbose           Verbose output"
          echo "  -h, --help              Show this help"
          echo ""
          echo "Examples:"
          echo "  $(basename "$0") firefox"
          echo "  $(basename "$0") -i wg1 curl https://ipinfo.io"
          echo "  $(basename "$0") -n my-vpn-ns transmission-gtk"
          exit 1
      }

      log() {
          if [[ "$VERBOSE" == "true" ]]; then
              echo "[vpn-run] $*" >&2
          fi
      }

      error() {
          echo "[vpn-run] ERROR: $*" >&2
          exit 1
      }

      check_interface() {
          if ! ip link show "$INTERFACE" >/dev/null 2>&1; then
              error "Interface '$INTERFACE' not found. Make sure your VPN is running."
          fi
      }

      cleanup_namespace() {
          if [[ "$CLEANUP_ON_EXIT" == "true" ]]; then
              log "Cleaning up namespace '$NAMESPACE'"
              ip netns del "$NAMESPACE" 2>/dev/null || true
              rm -f "/etc/netns/$NAMESPACE/resolv.conf" 2>/dev/null || true
              rmdir "/etc/netns/$NAMESPACE" 2>/dev/null || true
          fi
      }

      setup_namespace() {
          log "Setting up namespace '$NAMESPACE'"

          # Create namespace if it doesn't exist
          if ! ip netns list | grep -q "^$NAMESPACE\$"; then
              ip netns add "$NAMESPACE"
          fi

          VPN_IP=$(ip addr show "$INTERFACE" | grep -oP 'inet \K[^/]+' | head -n1)

          if [[ -z "$VPN_IP" ]]; then
              error "Could not determine IP address for interface '$INTERFACE'. Is the VPN connected?"
          fi

          VPN_CIDR=$(ip addr show "$INTERFACE" | grep -oP 'inet \K[^[:space:]]+' | head -n1)

          log "VPN IP: $VPN_CIDR"

          # Move interface to namespace
          ip link set "$INTERFACE" netns "$NAMESPACE"

          # Configure interface in namespace
          ip netns exec "$NAMESPACE" ip link set lo up
          ip netns exec "$NAMESPACE" ip link set "$INTERFACE" up

          # Restore IP configuration
          ip netns exec "$NAMESPACE" ip addr add "$VPN_CIDR" dev "$INTERFACE"

          # Set up routing - try to detect and preserve existing routes
          local gateway=""
          local existing_routes=""

          existing_routes=$(ip route show dev "$INTERFACE" 2>/dev/null | head -5 || true)

          if [[ -n "$existing_routes" ]]; then
              # Try to extract gateway from existing routes
              gateway=$(echo "$existing_routes" | grep -oP 'via \K[0-9.]+' | head -n1 || true)
          fi

          # Set default route
          if [[ -n "$gateway" ]]; then
              log "Using detected gateway: $gateway"
              ip netns exec "$NAMESPACE" ip route add default via "$gateway" dev "$INTERFACE"
          else
              log "Using direct routing via interface"
              ip netns exec "$NAMESPACE" ip route add default dev "$INTERFACE"
          fi

          # Setup DNS
          mkdir -p "/etc/netns/$NAMESPACE"

          # Try to use system DNS first, fall back to public DNS
          if [[ -f /etc/resolv.conf ]]; then
              cp /etc/resolv.conf "/etc/netns/$NAMESPACE/resolv.conf"
          else
              cat > "/etc/netns/$NAMESPACE/resolv.conf" << EOF
      nameserver 1.1.1.1
      nameserver 1.0.0.1
      nameserver 8.8.8.8
      EOF
          fi

          log "Namespace setup complete"
      }

      restore_interface() {
          log "Restoring interface '$INTERFACE' to main namespace"

          # Get current config before moving
          local current_config=""
          if ip netns exec "$NAMESPACE" ip link show "$INTERFACE" >/dev/null 2>&1; then
              current_config=$(ip netns exec "$NAMESPACE" ip addr show "$INTERFACE" 2>/dev/null | grep "inet " | awk '{print $2}' || true)

              # Move interface back to main namespace
              ip netns exec "$NAMESPACE" ip link set "$INTERFACE" netns 1

              # Restore basic configuration
              if [[ -n "$current_config" ]]; then
                  ip addr add "$current_config" dev "$INTERFACE" 2>/dev/null || true
                  ip link set "$INTERFACE" up 2>/dev/null || true
              fi
          fi

          log "Interface restored. Note: You may need to restart your VPN to fully restore routing."
      }

      run_in_namespace() {
          local cmd=("$@")

          log "Running command in namespace: ''${cmd[*]}"

          local orig_user=""

          if [[ -n "''${SUDO_USER:-}" ]]; then
              # Running via sudo
              orig_user="$SUDO_USER"
          elif [[ $EUID -eq 0 ]]; then
              # Running as root directly - use root
              orig_user="root"
          else
              # Running as regular user (shouldn't happen with current setup, but handle it)
              orig_user="$USER"
          fi

          ip netns exec "$NAMESPACE" \
              runuser -u "$orig_user" \
              --preserve-environment -- \
              "''${cmd[@]}"
      }

      main() {
          while [[ $# -gt 0 ]]; do
              case $1 in
                  -i|--interface)
                      INTERFACE="$2"
                      shift 2
                      ;;
                  -n|--namespace)
                      NAMESPACE="$2"
                      shift 2
                      ;;
                  -k|--keep-namespace)
                      CLEANUP_ON_EXIT=false
                      shift
                      ;;
                  -v|--verbose)
                      VERBOSE=true
                      shift
                      ;;
                  -h|--help)
                      usage
                      ;;
                  -*)
                      error "Unknown option: $1"
                      ;;
                  *)
                      break
                      ;;
              esac
          done

          if [[ $# -eq 0 ]]; then
              error "No command specified. Use -h for help."
          fi

          # Check if we're running as root (required for namespace operations)
          if [[ $EUID -ne 0 ]]; then
              error "This script must be run with elevated privileges. If you're in the vpn-run group, the setuid wrapper should handle this automatically."
          fi

          check_interface

          # Set up cleanup trap
          trap 'restore_interface; cleanup_namespace' EXIT INT TERM

          setup_namespace
          run_in_namespace "$@"
      }

      main "$@"
    '';
  };

in

{
  options.vpn-run = {
    enable = mkEnableOption "vpn-run service for routing commands through specific interfaces";

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
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ vpnRunScript ];

    security.wrappers = mkIf (cfg.allowedUsers != [ ]) {
      vpn-run = {
        source = "${vpnRunScript}/bin/vpn-run";
        owner = "root";
        group = "vpn-run";
        permissions = "u+rxs,g+rx";
        setuid = true;
      };
    };

    security.sudo.extraRules = mkIf (cfg.allowedUsers != [ ]) [
      {
        users = cfg.allowedUsers;
        commands = [
          {
            command = "${vpnRunScript}/bin/vpn-run";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/vpn-run";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/wrappers/bin/vpn-run";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];

    users.groups = mkIf (cfg.allowedUsers != [ ]) {
      vpn-run = {
        members = cfg.allowedUsers;
      };
    };
  };
}
