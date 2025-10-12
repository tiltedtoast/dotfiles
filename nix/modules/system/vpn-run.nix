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
      pkgs.util-linux
      pkgs.procps
      pkgs.netcat
      pkgs.iptables
      pkgs.coreutils
      pkgs.socat
    ];

    text = ''
      set -euo pipefail

      INTERFACE="${cfg.defaultInterface}"
      NAMESPACE="vpn-run-ns"
      CLEANUP_ON_EXIT=true
      VERBOSE=false

      # veth pair addressing
      VETH_HOST_CIDR="${cfg.vethHostAddress}"
      VETH_NS_CIDR="${cfg.vethNsAddress}"

      DISABLE_IPV6="${if cfg.disableIPv6 then "true" else "false"}"
      DROP_NON_VPN="${if cfg.dropNonVpnForward then "true" else "false"}"

      VETH_HOST_IP="''${VETH_HOST_CIDR%/*}"
      VETH_NS_IP="''${VETH_NS_CIDR%/*}"

      HOST_DNS_TARGET="''${VPN_RUN_HOST_DNS_TARGET:-}"

      # State
      ROUTE_TABLE_ID=""
      RULE_PRIORITY=""
      NAT_CHAIN=""
      FWD_CHAIN=""
      DNS_IN_CHAIN=""
      VETH_HOST=""
      VETH_NS=""
      DNS_TCP_PID=""
      DNS_UDP_PID=""
      SOCAT_LOG_DIR="/run/vpn-run-logs"
      SOCAT_TCP_LOG=""
      SOCAT_UDP_LOG=""

      usage() {
        echo "Usage: $(basename "$0") [OPTIONS] COMMAND [ARGS...]"
        echo ""
        echo "Run a command in an isolated network namespace that only egresses via a specific interface"
        echo "DNS inside the namespace is bridged to the host's resolver"
        echo ""
        echo "Options:"
        echo "  -i,  --interface NAME    VPN interface (default: ${cfg.defaultInterface})"
        echo "  -n,  --namespace NAME    Namespace name (default: vpn-run-ns)"
        echo "  -k,  --keep-namespace    Don't cleanup namespace on exit"
        echo "  -v,  --verbose           Verbose output"
        echo "  -h,  --help              Show this help"
        exit 1
      }

      log()   {
        if [[ "$VERBOSE" == "true" ]]; then
          echo "[vpn-run] $*" >&2 || true
        fi
      }

      error() {
        echo "[vpn-run] ERROR: $*" >&2
        exit 1
      }

      require_root() {
        if [[ ! $EUID -eq 0 ]]; then
          error "Run as root"
        fi
      }

      check_interface() {
        ip link show "$INTERFACE" >/dev/null 2>&1 || error "Interface '$INTERFACE' not found.";
      }

      # Interface names must be <= 15 chars
      gen_suffix() {
        printf "%04x" "$((RANDOM % 65536))"
      }

      ipt_add_once() {
        local table="$1"; shift;
        local chain="$1"; shift;
        iptables -t "$table" -C "$chain" "$@" 2>/dev/null || iptables -t "$table" -A "$chain" "$@"
      }

      ipt_insert_once() {
        local table="$1"; shift;
        local chain="$1"; shift;
        iptables -t "$table" -C "$chain" "$@" 2>/dev/null || iptables -t "$table" -I "$chain" "$@"
      }

      detect_host_dns_target() {
        if [[ -n "$HOST_DNS_TARGET" ]]; then
          return
        fi

        if command -v systemctl >/dev/null 2>&1 && systemctl -q is-active systemd-resolved; then
          HOST_DNS_TARGET="127.0.0.53:53"
        else
          HOST_DNS_TARGET="127.0.0.1:53"
        fi
      }

      start_dns_bridge() {
        detect_host_dns_target
        local t_ip="''${HOST_DNS_TARGET%:*}"
        local t_port="''${HOST_DNS_TARGET#*:}"

        log "Starting DNS bridge on $VETH_HOST_IP:53 -> $t_ip:$t_port (UDP+TCP) via socat"

        mkdir -p "$SOCAT_LOG_DIR"
        SOCAT_TCP_LOG="$SOCAT_LOG_DIR/socat-tcp-$NAMESPACE.log"
        SOCAT_UDP_LOG="$SOCAT_LOG_DIR/socat-udp-$NAMESPACE.log"

        # Explicitly allow DNS to the host on the veth INPUT path
        local suffix; suffix=$(gen_suffix)
        DNS_IN_CHAIN="VRN''${suffix}DNSI"

        iptables -N "$DNS_IN_CHAIN" 2>/dev/null || true
        iptables -C INPUT -i "$VETH_HOST" -j "$DNS_IN_CHAIN" 2>/dev/null || iptables -I INPUT -i "$VETH_HOST" -j "$DNS_IN_CHAIN"

        ipt_add_once filter "$DNS_IN_CHAIN" -p udp --dport 53 -j ACCEPT
        ipt_add_once filter "$DNS_IN_CHAIN" -p tcp --dport 53 -j ACCEPT

        # TCP bridge
        if [[ "$VERBOSE" == "true" ]]; then
          socat -d -d TCP4-LISTEN:53,bind="$VETH_HOST_IP",fork,reuseaddr TCP4:"$t_ip":"$t_port" >>"$SOCAT_TCP_LOG" 2>&1 &
        else
          socat TCP4-LISTEN:53,bind="$VETH_HOST_IP",fork,reuseaddr TCP4:"$t_ip":"$t_port" 2>/dev/null &
        fi
        DNS_TCP_PID=$!

        # UDP bridge (with timeout so forks GC if idle)
        if [[ "$VERBOSE" == "true" ]]; then
          socat -d -d -T60 UDP4-LISTEN:53,bind="$VETH_HOST_IP",fork,reuseaddr UDP4:"$t_ip":"$t_port" >>"$SOCAT_UDP_LOG" 2>&1 &
        else
          socat -T60 UDP4-LISTEN:53,bind="$VETH_HOST_IP",fork,reuseaddr UDP4:"$t_ip":"$t_port" 2>/dev/null &
        fi
        DNS_UDP_PID=$!

        # Wait for TCP to be listening
        for _ in {1..40}; do
          if ss -lnpt 2>/dev/null | grep -qE "[[:space:]]$VETH_HOST_IP:53[[:space:]].*socat"; then
            log "DNS TCP bridge is listening"
            break
          fi
          sleep 0.05
        done
      }

      stop_dns_bridge() {
        for pid in "$DNS_TCP_PID" "$DNS_UDP_PID"; do
          [[ -n "''${pid:-}" ]] || continue
          if kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null || true
            for _ in {1..10}; do kill -0 "$pid" 2>/dev/null || break; sleep 0.1; done
            kill -9 "$pid" 2>/dev/null || true
          fi
        done
      }

      cleanup_namespace() {
        log "Cleaning up (namespace: $NAMESPACE)"

        stop_dns_bridge

        if [[ -f "/run/vpn-run-$NAMESPACE.state" ]]; then
          # shellcheck disable=SC1090
          . "/run/vpn-run-$NAMESPACE.state" || true

          # iptables chains
          if [[ -n "''${NAT_CHAIN:-}" ]]; then
            iptables -t nat -D POSTROUTING -j "$NAT_CHAIN" 2>/dev/null || true
            iptables -t nat -F "$NAT_CHAIN" 2>/dev/null || true
            iptables -t nat -X "$NAT_CHAIN" 2>/dev/null || true
          fi

          if [[ -n "''${FWD_CHAIN:-}" ]]; then
            iptables -D FORWARD -j "$FWD_CHAIN" 2>/dev/null || true
            iptables -F "$FWD_CHAIN" 2>/dev/null || true
            iptables -X "$FWD_CHAIN" 2>/dev/null || true
          fi

          if [[ -n "''${DNS_IN_CHAIN:-}" ]]; then
            iptables -D INPUT -i "$VETH_HOST" -j "$DNS_IN_CHAIN" 2>/dev/null || true
            iptables -F "$DNS_IN_CHAIN" 2>/dev/null || true
            iptables -X "$DNS_IN_CHAIN" 2>/dev/null || true
          fi

          # policy routing
          if [[ -n "''${RULE_PRIORITY:-}" && -n "''${ROUTE_TABLE_ID:-}" ]]; then
            ip rule del priority "$RULE_PRIORITY" 2>/dev/null || \
            ip rule del from "$VETH_NS_IP/32" lookup "$ROUTE_TABLE_ID" 2>/dev/null || true
            ip route flush table "$ROUTE_TABLE_ID" 2>/dev/null || true
          fi

          rm -f "/run/vpn-run-$NAMESPACE.state" 2>/dev/null || true
        fi

        # Drop veth pair
        if [[ -n "''${VETH_HOST:-}" ]]; then
          ip link del "$VETH_HOST" 2>/dev/null || true
        fi

        if [[ "$CLEANUP_ON_EXIT" == "true" ]]; then
          ip netns del "$NAMESPACE" 2>/dev/null || true
          rm -f "/etc/netns/$NAMESPACE/nsswitch.conf" "/etc/netns/$NAMESPACE/resolv.conf" 2>/dev/null || true
          rmdir "/etc/netns/$NAMESPACE" 2>/dev/null || true
        fi
      }

      configure_host_egress() {
        log "Configuring host NAT, policy routing, and forwarding to '$INTERFACE'"

        sysctl -q -w net.ipv4.ip_forward=1 || true
        sysctl -q -w net.ipv4.conf.all.rp_filter=0 || true
        sysctl -q -w net.ipv4.conf.default.rp_filter=0 || true
        sysctl -q -w net.ipv4.conf."$INTERFACE".rp_filter=0 || true
        sysctl -q -w net.ipv4.conf."$VETH_HOST".rp_filter=0 || true

        local suffix; suffix=$(gen_suffix)
        NAT_CHAIN="VRN''${suffix}NAT"
        FWD_CHAIN="VRN''${suffix}FWD"

        iptables -t nat -N "$NAT_CHAIN" 2>/dev/null || true
        iptables -t filter -N "$FWD_CHAIN" 2>/dev/null || true

        ipt_insert_once nat POSTROUTING -j "$NAT_CHAIN"
        ipt_insert_once filter FORWARD -j "$FWD_CHAIN"

        # NAT: only ns IP out the VPN interface
        ipt_add_once nat "$NAT_CHAIN" -s "$VETH_NS_IP/32" -o "$INTERFACE" -j MASQUERADE

        # Forwarding: allow ns->vpn and established return
        ipt_add_once filter "$FWD_CHAIN" -i "$VETH_HOST" -o "$INTERFACE" -j ACCEPT
        ipt_add_once filter "$FWD_CHAIN" -i "$INTERFACE" -o "$VETH_HOST" -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

        # Prevent bypass DNS (force using host bridge)
        ipt_add_once filter "$FWD_CHAIN" -i "$VETH_HOST" -p udp --dport 53 -j REJECT
        ipt_add_once filter "$FWD_CHAIN" -i "$VETH_HOST" -p tcp --dport 53 -j REJECT

        # Optionally drop any ns->non-VPN forwarding
        if [[ "$DROP_NON_VPN" == "true" ]]; then
          ipt_add_once filter "$FWD_CHAIN" -i "$VETH_HOST" ! -o "$INTERFACE" -j REJECT
        fi

        # Policy routing: force ns source out via VPN
        ROUTE_TABLE_ID=$(( 10000 + (RANDOM % 5000) ))
        RULE_PRIORITY=$(( 10000 + (RANDOM % 5000) ))

        ip route add table "$ROUTE_TABLE_ID" default dev "$INTERFACE" 2>/dev/null \
          || ip route replace table "$ROUTE_TABLE_ID" default dev "$INTERFACE"
        ip rule add from "$VETH_NS_IP/32" table "$ROUTE_TABLE_ID" priority "$RULE_PRIORITY"

        log "Policy routing: prio $RULE_PRIORITY from $VETH_NS_IP/32 -> table $ROUTE_TABLE_ID (default via $INTERFACE)"
      }

      setup_namespace() {
        log "Setting up namespace '$NAMESPACE' with veth pair"

        ip netns list | grep -q "^$NAMESPACE$" || ip netns add "$NAMESPACE"

        local suffix; suffix=$(gen_suffix)
        VETH_HOST="vrnh-$suffix"
        VETH_NS="vrnn-$suffix"

        ip link add "$VETH_HOST" type veth peer name "$VETH_NS"

        local mtu; mtu=$(cat "/sys/class/net/$INTERFACE/mtu" 2>/dev/null || echo 1420)
        ip link set dev "$VETH_HOST" mtu "$mtu"
        ip link set dev "$VETH_NS" mtu "$mtu"

        ip link set "$VETH_NS" netns "$NAMESPACE"

        ip addr add "$VETH_HOST_CIDR" dev "$VETH_HOST"
        ip link set "$VETH_HOST" up

        ip netns exec "$NAMESPACE" ip link set lo up
        ip netns exec "$NAMESPACE" ip addr add "$VETH_NS_CIDR" dev "$VETH_NS"
        ip netns exec "$NAMESPACE" ip link set "$VETH_NS" up

        if [[ "$DISABLE_IPV6" == "true" ]]; then
          log "Disabling IPv6 inside namespace"
          ip netns exec "$NAMESPACE" sysctl -q -w net.ipv6.conf.all.disable_ipv6=1 || true
          ip netns exec "$NAMESPACE" sysctl -q -w net.ipv6.conf.default.disable_ipv6=1 || true
        fi

        # Default route inside namespace via host-veth
        ip netns exec "$NAMESPACE" ip route add default via "$VETH_HOST_IP" dev "$VETH_NS"

        # Per-netns NSS/DNS
        mkdir -p "/etc/netns/$NAMESPACE"

        cat > "/etc/netns/$NAMESPACE/resolv.conf" << EOF
      nameserver $VETH_HOST_IP
      options edns0
      EOF
        log "DNS configured to use host via $VETH_HOST_IP"

        configure_host_egress
        start_dns_bridge

        # Persist state
        {
          echo "NAT_CHAIN=$NAT_CHAIN"
          echo "FWD_CHAIN=$FWD_CHAIN"
          echo "DNS_IN_CHAIN=$DNS_IN_CHAIN"
          echo "VETH_HOST=$VETH_HOST"
          echo "VETH_NS=$VETH_NS"
          echo "ROUTE_TABLE_ID=$ROUTE_TABLE_ID"
          echo "RULE_PRIORITY=$RULE_PRIORITY"
          echo "HOST_DNS_TARGET=$HOST_DNS_TARGET"
          echo "DNS_TCP_PID=$DNS_TCP_PID"
          echo "DNS_UDP_PID=$DNS_UDP_PID"
        } > "/run/vpn-run-$NAMESPACE.state"

        log "Namespace setup complete"
        if [[ "$VERBOSE" == "true" ]]; then
          ss -lnptu | grep -E "$VETH_HOST_IP:53|127\.0\.0\.5[34]:53" || true
          [[ -f "$SOCAT_TCP_LOG" ]] && tail -n +1 "$SOCAT_TCP_LOG" | sed 's/^/[socat-tcp] /' >&2 || true
        fi
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
          orig_user="$USER"
        fi

        ip netns exec "$NAMESPACE" \
          runuser -u "$orig_user" \
          --preserve-environment \
          -- "''${cmd[@]}"
      }

      main() {
        while [[ $# -gt 0 ]]; do
          case $1 in
            -i|--interface) INTERFACE="$2"; shift 2 ;;
            -n|--namespace) NAMESPACE="$2"; shift 2 ;;
            -k|--keep-namespace) CLEANUP_ON_EXIT=false; shift ;;
            -v|--verbose) VERBOSE=true; shift ;;
            -h|--help) usage ;;
            -*) error "Unknown option: $1" ;;
            *) break ;;
          esac
        done

        [[ $# -gt 0 ]] || error "No command specified. Use -h for help."

        require_root
        check_interface

        trap 'cleanup_namespace' EXIT INT TERM

        setup_namespace
        run_in_namespace "$@"
      }

      main "$@"
    '';
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

    useCloudflared = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to use cloudflared as DoH proxy for DNS resolution";
    };

    dohConfigFile = mkOption {
      type = types.str;
      default = "/etc/vpn-run/doh.conf";
      description = "Path to file containing DoH URL configuration";
      example = "/etc/vpn-run/doh.conf";
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
