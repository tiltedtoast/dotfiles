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
      pkgs.cloudflared
      pkgs.procps
      pkgs.netcat
    ];

    text = ''
      set -euo pipefail

      INTERFACE="${cfg.defaultInterface}"
      NAMESPACE="vpn-run-ns"
      CLEANUP_ON_EXIT=true
      VERBOSE=false
      DOH_CONFIG_FILE="${cfg.dohConfigFile}"
      USE_CLOUDFLARED="${if cfg.useCloudflared then "true" else "false"}"
      CLOUDFLARED_PORT="${toString cfg.cloudflaredPort}"

      usage() {
          echo "Usage: $(basename "$0") [OPTIONS] COMMAND [ARGS...]"
          echo ""
          echo "Run a command in a network namespace with only VPN access"
          echo ""
          echo "Options:"
          echo "  -i,  --interface NAME    VPN interface name (default: ${cfg.defaultInterface})"
          echo "  -n,  --namespace NAME    Namespace name (default: vpn-run-ns)"
          echo "  -k,  --keep-namespace    Don't cleanup namespace on exit"
          echo "  -v,  --verbose           Verbose output"
          echo "  -d,  --doh-config FILE   DoH config file path (default: ${cfg.dohConfigFile})"
          echo "  -c,  --cloudflared       Force enable cloudflared DoH proxy"
          echo "  -nc, --no-cloudflared    Disable cloudflared DoH proxy"
          echo "  -h,  --help              Show this help"
          echo ""
          echo "Examples:"
          echo "  $(basename "$0") firefox"
          echo "  $(basename "$0") -i wg1 curl ifconfig.me"
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

      read_doh_config() {
          local doh_url=""

          if [[ -f "$DOH_CONFIG_FILE" ]]; then
              # Read the first non-empty, non-comment line
              doh_url=$(grep -v '^#' "$DOH_CONFIG_FILE" | grep -v '^[[:space:]]*$' | head -n1 | xargs)
              log "Read DoH URL from config: $doh_url"
          fi

          echo "$doh_url"
      }

      start_cloudflared() {
          local doh_url="$1"

          if [[ -z "$doh_url" ]]; then
              log "No DoH URL provided, using Cloudflare's default (1.1.1.1)"
              doh_url="https://1.1.1.1/dns-query"
          fi

          log "Starting cloudflared DNS proxy with DoH URL: $doh_url"

          ip netns exec "$NAMESPACE" cloudflared proxy-dns \
              --address "127.0.0.1" \
              --port "$CLOUDFLARED_PORT" \
              --upstream "$doh_url" \
              2> /dev/null &

          local cloudflared_pid=$!
          echo "$cloudflared_pid" > "/tmp/vpn-run-cloudflared-$NAMESPACE.pid"

            for _ in {1..50}; do
              if ip netns exec "$NAMESPACE" nc -z 127.0.0.1 "$CLOUDFLARED_PORT" 2>/dev/null; then
                log "cloudflared is ready"
                break
              fi
              sleep 0.1
            done

          if ! kill -0 "$cloudflared_pid" 2>/dev/null; then
              error "Failed to start cloudflared DNS proxy"
          fi

          log "Cloudflared started with PID: $cloudflared_pid"
      }

      stop_cloudflared() {
          local pid_file="/tmp/vpn-run-cloudflared-$NAMESPACE.pid"

          if [[ -f "$pid_file" ]]; then
              local cloudflared_pid
              cloudflared_pid=$(cat "$pid_file")

              if kill -0 "$cloudflared_pid" 2>/dev/null; then
                  log "Stopping cloudflared (PID: $cloudflared_pid)"
                  kill "$cloudflared_pid" 2>/dev/null || true

                  # Wait for graceful shutdown
                  local count=0
                  while kill -0 "$cloudflared_pid" 2>/dev/null && [[ $count -lt 10 ]]; do
                      sleep 1
                      ((count++))
                  done

                  # Force kill if still running
                  if kill -0 "$cloudflared_pid" 2>/dev/null; then
                      log "Force killing cloudflared"
                      kill -9 "$cloudflared_pid" 2>/dev/null || true
                  fi
              fi

              rm -f "$pid_file"
          fi
      }

      cleanup_namespace() {
          if [[ "$CLEANUP_ON_EXIT" == "true" ]]; then
              log "Cleaning up namespace '$NAMESPACE'"
              ip netns del "$NAMESPACE" 2>/dev/null || true

              stop_cloudflared

              rm -f "/etc/netns/$NAMESPACE/nsswitch.conf" 2>/dev/null || true
              rm -f "/etc/netns/$NAMESPACE/resolv.conf" 2>/dev/null || true
              rmdir "/etc/netns/$NAMESPACE" 2>/dev/null || true
          fi
      }

      setup_namespace() {
          log "Setting up namespace '$NAMESPACE'"

          if ! ip netns list | grep -q "^$NAMESPACE\$"; then
              ip netns add "$NAMESPACE"
          fi

          VPN_IP=$(ip addr show "$INTERFACE" | grep -oP 'inet \K[^/]+' | head -n1)

          if [[ -z "$VPN_IP" ]]; then
              error "Could not determine IP address for interface '$INTERFACE'. Is the VPN connected?"
          fi

          VPN_CIDR=$(ip addr show "$INTERFACE" | grep -oP 'inet \K[^[:space:]]+' | head -n1)

          log "VPN IP: $VPN_CIDR"

          ip link set "$INTERFACE" netns "$NAMESPACE"

          ip netns exec "$NAMESPACE" ip link set lo up
          ip netns exec "$NAMESPACE" ip link set "$INTERFACE" up

          ip netns exec "$NAMESPACE" ip addr add "$VPN_CIDR" dev "$INTERFACE"

          local gateway=""
          local existing_routes=""

          existing_routes=$(ip route show dev "$INTERFACE" 2>/dev/null | head -5 || true)

          if [[ -n "$existing_routes" ]]; then
              # Try to extract gateway from existing routes
              gateway=$(echo "$existing_routes" | grep -oP 'via \K[0-9.]+' | head -n1 || true)
          fi

          if [[ -n "$gateway" ]]; then
              log "Using detected gateway: $gateway"
              ip netns exec "$NAMESPACE" ip route add default via "$gateway" dev "$INTERFACE"
          else
              log "Using direct routing via interface"
              ip netns exec "$NAMESPACE" ip route add default dev "$INTERFACE"
          fi

          mkdir -p "/etc/netns/$NAMESPACE"

          cat > "/etc/netns/$NAMESPACE/nsswitch.conf" << EOF
      # Use traditional DNS and local files for host resolution, bypassing systemd-resolved.
      hosts:      files dns
      EOF
          log "Created custom nsswitch.conf to bypass systemd-resolved"

          if [[ "$USE_CLOUDFLARED" == "true" ]]; then
              local doh_url
              doh_url=$(read_doh_config)

              start_cloudflared "$doh_url"

              cat > "/etc/netns/$NAMESPACE/resolv.conf" << EOF
      nameserver 127.0.0.1
      options edns0
      EOF
              log "DNS configured to use cloudflared proxy on 127.0.0.1:$CLOUDFLARED_PORT"
          else
              cat > "/etc/netns/$NAMESPACE/resolv.conf" << EOF
      nameserver 1.1.1.1
      nameserver 8.8.8.8
      nameserver 1.0.0.1
      nameserver 8.8.4.4
      EOF
              log "DNS configured with fallback servers"
          fi

          log "Namespace setup complete"
      }

      restore_interface() {
          log "Restoring interface '$INTERFACE' to main namespace"

          local current_config=""
          if ip netns exec "$NAMESPACE" ip link show "$INTERFACE" >/dev/null 2>&1; then
              current_config=$(ip netns exec "$NAMESPACE" ip addr show "$INTERFACE" 2>/dev/null | grep "inet " | awk '{print $2}' || true)

              ip netns exec "$NAMESPACE" ip link set "$INTERFACE" netns 1

              if [[ -n "$current_config" ]]; then
                  ip addr add "$current_config" dev "$INTERFACE" 2>/dev/null || true
                  ip link set "$INTERFACE" up 2>/dev/null || true
              fi
          fi

          log "Interface restored"
      }

      run_in_namespace() {
          local cmd=("$@")

          log "Running command in namespace: ''${cmd[*]}"

          local orig_user=""

          if [[ -n "''${SUDO_USER:-}" ]]; then
              orig_user="$SUDO_USER"
          elif [[ $EUID -eq 0 ]]; then
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
                  -d|--doh-config)
                      DOH_CONFIG_FILE="$2"
                      shift 2
                      ;;
                  -c|--cloudflared)
                      USE_CLOUDFLARED=true
                      shift
                      ;;
                  -nc|--no-cloudflared)
                      USE_CLOUDFLARED=false
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

          if [[ $EUID -ne 0 ]]; then
              error "This script must be run with elevated privileges. If you're in the vpn-run group, the setuid wrapper should handle this automatically."
          fi

          check_interface

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

    shellAlias = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to create a shell alias for vpn-run";
    };

    useCloudflared = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to use cloudflared as DoH proxy for DNS resolution";
    };

    dohConfigFile = mkOption {
      type = types.str;
      description = "Path to file containing DoH URL configuration";
      example = "/etc/vpn-run/doh.conf";
    };

    cloudflaredPort = mkOption {
      type = types.port;
      default = 53;
      description = "Port for cloudflared DNS proxy to listen on";
      example = 53;
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ vpnRunScript ];

    security.wrappers.vpn-run = mkIf (cfg.allowedUsers != [ ]) {
      source = "${vpnRunScript}/bin/vpn-run";
      owner = "root";
      group = "vpn-run";
      permissions = "u+rxs,g+rx";
      setuid = true;
    };

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
          {
            command = "/run/wrappers/bin/vpn-run";
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
