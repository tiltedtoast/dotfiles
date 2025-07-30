{
  pkgs,
  lib,
  ...
}:

let
  cfg = config.fingerprint;
in
with lib;
{
  options.fingerprint = {
    enable = mkEnableOption "enable fingerprint scanning";

    fprintd_package = mkOption {
      type = types.package;
      default = pkgs.fprintd;
      defaultText = "pkgs.fprintd";
      description = "Which package to use for fprintd";
    };

    libfprint_package = mkOption {
      type = types.package;
      default = pkgs.libfprint;
      defaultText = "pkgs.libfprint";
      description = "Which package to use for libfprint";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      cfg.fprintd_package
      cfg.libfprint_package
    ];
    services.fprintd.enable = true;

    systemd.services.fprintd = {
      wantedBy = [ "multi-user.target" ];
      serviceConfig.Type = "simple";
    };

    services.fprintd.package = pkgs.fprintd.override {
      libfprint = cfg.libfprint_package;
    };

    # If we want to manage fingerprints via the plasma GUI we need to allow this
    # At least with the elanmoc2 driver this seems to be necessary, idk about other drivers
    environment.etc."polkit-1/rules.d/45-fprintd.rules" = mkIf config.desktopManager.plasma6.enable {
      text = ''
        polkit.addRule(function(action, subject) {
          if (action.id.match(/^net\.reactivated\.fprint\.device\./)) {
              return polkit.Result.YES;
          }
        });
      '';
      mode = "0644";
    };
  };
}
