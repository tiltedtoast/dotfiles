{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.hdr;

  hdr-toggle-script = pkgs.writeShellScriptBin "hdr-toggle" ''
    DEFAULT_OUTPUT="${cfg.defaultOutput}"
    DEFAULT_ICC_PROFILE="${cfg.defaultIccProfile}"

    TOGGLE="''${1:-toggle}"
    OUTPUT="''${2:-$DEFAULT_OUTPUT}"

    # Variable juggling to make sure the default ICC profile is only applied
    # to the default output in cases where multiple monitors are present.
    declare ICCPROF_''${DEFAULT_OUTPUT//-/_}="''${DEFAULT_ICC_PROFILE}"
    ICCPROF=ICCPROF_''${OUTPUT//-/_}

    # Pre-flight checks
    if [[ ! $DESKTOP_SESSION == "plasma" ]] || [[ $DISABLE_HDR_TOGGLING == "true" ]]; then
      echo "Plasma desktop not active or DISABLE_HDR_TOGGLING has been set to true. Bailing."
      exit 0
    fi
    if ! command -v kscreen-doctor &> /dev/null; then
      echo "Error: kscreen-doctor could not be found. Bailing."
      exit 1
    fi

    OUTPUT_HDR_STATE=$(kscreen-doctor -j | jq -r --arg name "$OUTPUT" '
      ( .outputs[] | select(.name == $name) |
        if has("hdr") then
          if .hdr then "enabled" else "disabled" end
        else
          "incapable"
        end
      ) // "incapable"
    ')

    if [[ $OUTPUT_HDR_STATE == "incapable" ]]; then
      echo "Output $OUTPUT reports HDR is incapable. Quitting..."
      exit 1
    fi
    if [[ -z "$OUTPUT_HDR_STATE" ]]; then
      echo "Output $OUTPUT not found or HDR status could not be determined. See 'kscreen-doctor -o'. Quitting..."
      exit 1
    fi

    function hdr_disable() {
      echo "$OUTPUT: Toggling HDR off"
      local ICCPROF_
      if [[ -n "$3" ]]; then
        ICCPROF_=$3
      else
        ICCPROF_=''${!ICCPROF}
      fi
      kscreen-doctor output.$OUTPUT.hdr.disable output.$OUTPUT.wcg.disable output.$OUTPUT.iccprofile."$ICCPROF_" >/dev/null 2>&1
    }

    function hdr_enable() {
      echo "$OUTPUT: Toggling HDR on"
      kscreen-doctor output.$OUTPUT.hdr.enable output.$OUTPUT.wcg.enable >/dev/null 2>&1
    }

    show_usage() {
        cat << EOF
    Usage:
    $(basename $0) [enable|disable|toggle|help] [output] [ICC profile]

    KDE Plasma desktop HDR toggler. Utilises kscreen-doctor.
    To be used with launch wrapper scripts or command lines such as Steam or Lutris.

    Steam:
    '$(basename $0) enable; %command%; $(basename $0) disable'

    Lutris:
    Pre-launch script: '$(basename $0) enable'
    Post-exit script: '$(basename $0) disable'

    See 'kscreen-doctor -o' to list available outputs.
    To disable this script globally, run: 'export DISABLE_HDR_TOGGLING=true'.
    EOF
    }

    case $TOGGLE in
      toggle)
        case $OUTPUT_HDR_STATE in
          enabled)
            hdr_disable
            ;;
          disabled)
            hdr_enable
            ;;
          *)
            echo "OUTPUT_HDR_STATE: '$OUTPUT_HDR_STATE' - Unexpected value. Bailing..."
            exit 2
            ;;
        esac
        ;;
      enable)
        if [[ "$OUTPUT_HDR_STATE" != "enabled" ]]; then
            hdr_enable
        else
            echo "$OUTPUT: HDR is already enabled."
        fi
        ;;
      disable)
        if [[ "$OUTPUT_HDR_STATE" == "enabled" ]]; then
            hdr_disable
        else
            echo "$OUTPUT: HDR is already disabled."
        fi
        ;;
      help|h|-h|--help)
        show_usage
        ;;
      *)
        echo "Unknown command: $1."
        show_usage
        exit 2
        ;;
    esac

    exit 0
  '';

  hdr-enable-script = pkgs.writeShellScriptBin "hdr-enable" ''
    exec ${hdr-toggle-script}/bin/hdr-toggle enable "$@"
  '';

  hdr-disable-script = pkgs.writeShellScriptBin "hdr-disable" ''
    exec ${hdr-toggle-script}/bin/hdr-toggle disable "$@"
  '';
in

{
  options.hdr = {
    enable = mkEnableOption "KDE Plasma HDR toggling support";

    defaultOutput = mkOption {
      type = types.str;
      default = "DP-1";
      description = ''
        Default display output to use when no output is specified.
        Use 'kscreen-doctor -o' to list available outputs.
      '';
      example = "HDMI-A-1";
    };

    defaultIccProfile = mkOption {
      type = types.str;
      default = "";
      description = ''
        Default ICC profile path to apply when HDR is disabled.
        Leave empty to skip ICC profile application.
      '';
      example = "/home/user/.local/share/icc/my-display-profile.icc";
    };

    package = mkOption {
      type = types.package;
      default = hdr-toggle-script;
      defaultText = literalExpression "hdr-toggle-script";
      description = ''
        The main hdr-toggle package to use.
      '';
    };

    extraScripts = mkEnableOption "extra helper scripts (hdr-enable, hdr-disable)";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      cfg.package
      pkgs.vulkan-hdr-layer-kwin6
    ]
    ++ lib.optionals cfg.extraScripts [
      hdr-enable-script
      hdr-disable-script
    ]
    ++ (
      let
        mpv-hdr-script = pkgs.writeShellScriptBin "mpv-hdr" ''
          ENABLE_HDR_WSI=1 mpv --vo=gpu-next --target-colorspace-hint --gpu-api=vulkan --gpu-context=waylandvk "$@"
        '';

        mpv-hdr-auto-script = pkgs.writeShellScriptBin "mpv-hdr-auto" ''
          hdr-toggle enable
          ${mpv-hdr-script}/bin/mpv-hdr "$@"
          hdr-toggle disable
        '';
      in
      [
        mpv-hdr-script
        mpv-hdr-auto-script
      ]
    );
  };
}
