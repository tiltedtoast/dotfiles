{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.vpn-run;

  bindToInterfaceSource =
    pkgs.writeText "bind_to_interface.c" /*c*/ ''
      #define _GNU_SOURCE
      #include <sys/socket.h>
      #include <dlfcn.h>
      #include <string.h>
      #include <stdlib.h>
      #include <stdio.h>
      #include <errno.h>

      int socket(int domain, int type, int protocol) {
          int (*original_socket)(int, int, int) = dlsym(RTLD_NEXT, "socket");
          int sockfd = original_socket(domain, type, protocol);

          if (sockfd >= 0 && (domain == AF_INET || domain == AF_INET6)) {
              const char* interface = getenv("BIND_INTERFACE");
              if (interface && strlen(interface) > 0) {
                  if (setsockopt(sockfd, SOL_SOCKET, SO_BINDTODEVICE,
                                interface, strlen(interface)) < 0) {
                      // Only print error in debug mode to avoid spam
                      if (getenv("VPN_RUN_DEBUG")) {
                          fprintf(stderr, "vpn-run: Warning: Failed to bind to interface %s: %s\n",
                                  interface, strerror(errno));
                      }
                  }
              }
          }
          return sockfd;
      }

      int connect(int sockfd, const struct sockaddr *addr, socklen_t addrlen) {
          int (*original_connect)(int, const struct sockaddr *, socklen_t) = dlsym(RTLD_NEXT, "connect");

          const char* interface = getenv("BIND_INTERFACE");
          if (interface && strlen(interface) > 0) {
              setsockopt(sockfd, SOL_SOCKET, SO_BINDTODEVICE, interface, strlen(interface));
          }

          return original_connect(sockfd, addr, addrlen);
      }
  '';

  bindToInterfaceLib = pkgs.stdenv.mkDerivation {
    name = "bind-to-interface";
    version = "1.0.0";

    src = bindToInterfaceSource;

    unpackPhase = "true";

    buildPhase = ''
      gcc -shared -fPIC -o bind_to_interface.so ${bindToInterfaceSource} -ldl
    '';

    installPhase = ''
      mkdir -p $out/lib
      cp bind_to_interface.so $out/lib/
    '';

    buildInputs = [
      pkgs.gcc
      pkgs.glibc
    ];
  };

  vpnRunScript = pkgs.writeScriptBin "vpn-run" ''
    #!${pkgs.bash}/bin/bash

    DEFAULT_INTERFACE="${cfg.defaultInterface}"
    BIND_LIB="${bindToInterfaceLib}/lib/bind_to_interface.so"

    show_help() {
        cat << EOF
    vpn-run - Route command traffic through specific network interface

    Usage: vpn-run [options] <command> [args...]

    Options:
        -i, --interface <name>    Use specific interface (default: $DEFAULT_INTERFACE)
        -d, --debug              Enable debug output
        -v, --verbose            Show interface binding info
        -h, --help               Show this help
        -t, --test               Test interface binding

    Examples:
        vpn-run curl ifconfig.me
        vpn-run -i wg0 wget https://example.com
        vpn-run -i eth1 firefox
        vpn-run -d -i wg0 transmission-cli

    Current default interface: $DEFAULT_INTERFACE
    EOF
    }

    test_binding() {
        local interface="$1"
        echo "Testing interface binding for: $interface"

        # Check if interface exists
        if ! ip link show "$interface" >/dev/null 2>&1; then
            echo "Error: Interface '$interface' does not exist"
            echo "Available interfaces:"
            ip link show | grep -E '^[0-9]+:' | cut -d: -f2 | sed 's/^ */  /'
            return 1
        fi

        # Check if interface is up
        if ! ip link show "$interface" | grep -q "state UP"; then
            echo "Warning: Interface '$interface' is not UP"
        else
            echo "Interface '$interface' is UP"
        fi

        # Test basic connectivity through interface
        echo "Testing connectivity through $interface..."
        if BIND_INTERFACE="$interface" LD_PRELOAD="$BIND_LIB" \
           timeout 5 ${pkgs.curl}/bin/curl -s --max-time 3 ifconfig.me >/dev/null 2>&1; then
            echo "Connectivity test successful"
        else
            echo "Connectivity test failed"
        fi

        return 0
    }

    INTERFACE="$DEFAULT_INTERFACE"
    DEBUG_MODE=""
    VERBOSE_MODE=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            -i|--interface)
                INTERFACE="$2"
                shift 2
                ;;
            -d|--debug)
                DEBUG_MODE="1"
                shift
                ;;
            -v|--verbose)
                VERBOSE_MODE="1"
                shift
                ;;
            -t|--test)
                test_binding "''${2:-$INTERFACE}"
                exit $?
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            --)
                shift
                break
                ;;
            -*)
                echo "Unknown option: $1"
                echo "Use -h for help"
                exit 1
                ;;
            *)
                break
                ;;
        esac
    done

    # Check if command provided
    if [[ $# -eq 0 ]]; then
        echo "Error: No command specified"
        echo "Use -h for help"
        exit 1
    fi

    # Check if interface exists
    if ! ip link show "$INTERFACE" >/dev/null 2>&1; then
        echo "Error: Interface '$INTERFACE' does not exist"
        echo "Available interfaces:"
        ip link show | grep -E '^[0-9]+:' | cut -d: -f2 | sed 's/^ */  /'
        exit 1
    fi

    if [[ -n "$VERBOSE_MODE" ]]; then
        echo "Routing traffic through interface: $INTERFACE"
        echo "Command: $*"
        echo "Using library: $BIND_LIB"
    fi

    export BIND_INTERFACE="$INTERFACE"
    export LD_PRELOAD="$BIND_LIB"

    if [[ -n "$DEBUG_MODE" ]]; then
        export VPN_RUN_DEBUG="1"
        echo "Debug mode enabled"
    fi

    exec "$@"
  '';

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
        permissions = "u+rx,g+rx";
      };
    };

    users.groups = mkIf (cfg.allowedUsers != [ ]) {
      vpn-run = {
        members = cfg.allowedUsers;
      };
    };
  };
}
