{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

let
  cfg = config.disableWakeFromHibernate;
  script = ''
    #!${pkgs.bash}/bin/bash

    case "$1" in
      pre)
        # Disable the `power/wakeup` flag for devices where it exists.
        for f in /sys/bus/usb/devices/*/power/wakeup; do
          [ -e "$f" ] || continue
          echo disabled > "$f" 2>/dev/null || true
        done
        ;;
      post)
        # Re-enable those wakeup flags on resume
        for f in /sys/bus/usb/devices/*/power/wakeup; do
          [ -e "$f" ] || continue
          echo enabled > "$f" 2>/dev/null || true
        done
        ;;
      *)
        ;;
    esac
  '';

in
{
  options.disableWakeFromHibernate = {
    enable = mkEnableOption "service to disable wakeup from hibernate for usb devices";
  };

  config = mkIf cfg.enable {
    environment.etc."systemd/system-sleep/disable_wakeup.sh" = {
      text = script;
      mode = "0755";
    };
  };
}
