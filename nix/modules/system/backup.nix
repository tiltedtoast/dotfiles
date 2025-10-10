{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.gdriveBackup;
in
{
  options.gdriveBackup = {
    enable = mkEnableOption "Google Drive backup service";

    paths = mkOption {
      type = with types; listOf str;
      default = [ ];
      description = ''
        List of paths to backup to Google Drive.
      '';
      example = [
        "/home/user/Documents"
        "/home/user/Pictures"
        "/etc/nixos"
      ];
    };

    exclude = mkOption {
      type = with types; listOf str;
      default = [ ];
      description = ''
        Patterns to exclude from backup.
      '';
      example = [
        "*.tmp"
        ".cache"
        "node_modules"
      ];
    };

    rcloneRemoteName = mkOption {
      type = types.str;
      default = "gdrive";
      description = ''
        Name of the rclone remote configured for Google Drive.
        This should match a remote configured in your rclone config.
      '';
      example = "gdrive";
    };

    backupPath = mkOption {
      type = types.str;
      default = "backups";
      description = ''
        Path within Google Drive where backups will be stored.
      '';
      example = "restic-backups/hostname";
    };

    passwordFile = mkOption {
      type = types.path;
      description = ''
        Path to file containing the restic repository password.
      '';
      example = "/run/secrets/restic-password";
    };

    rcloneConfigFile = mkOption {
      type = with types; nullOr path;
      default = null;
      description = ''
        Path to rclone configuration file containing Google Drive credentials.
        If null, uses the default rclone config location (~/.config/rclone/rclone.conf).
      '';
      example = "/run/secrets/rclone.conf";
    };

    timerConfig = mkOption {
      type = with types; nullOr attrs;
      default = {
        OnCalendar = "daily";
        Persistent = true;
        RandomizedDelaySec = "1h";
      };
      description = ''
        When to run the backup. See systemd.timer(5) for details.
      '';
      example = {
        OnCalendar = "02:00";
        Persistent = true;
      };
    };

    pruneOpts = mkOption {
      type = with types; listOf str;
      default = [
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 6"
        "--keep-yearly 3"
      ];
      description = ''
        Retention policy for old backups.
      '';
    };

    initialize = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Automatically initialize the repository if it doesn't exist.
      '';
    };

    extraBackupArgs = mkOption {
      type = with types; listOf str;
      default = [ ];
      description = ''
        Extra arguments to pass to restic backup command.
      '';
      example = [
        "--verbose"
        "--exclude-caches"
      ];
    };

    rcloneOptions = mkOption {
      type =
        with types;
        attrsOf (oneOf [
          str
          bool
          int
        ]);
      default = { };
      description = ''
        Additional options to pass to rclone. See rclone docs for details.
        Note that boolean flags should be set to `true`.
      '';
      example = {
        drive-chunk-size = "64M";
        drive-upload-cutoff = "8M";
        drive-use-trash = false;
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.paths != [ ];
        message = "gdriveBackup.paths must not be empty";
      }
      {
        assertion = cfg.passwordFile != null;
        message = "gdriveBackup.passwordFile must be set";
      }
    ];

    services.restic.backups.gdrive = {
      repository = "rclone:${cfg.rcloneRemoteName}:${cfg.backupPath}";
      passwordFile = cfg.passwordFile;

      environmentFile = mkIf (cfg.rcloneConfigFile != null) (
        toString (
          pkgs.writeText "gdrive-rclone-env" ''
            RCLONE_CONFIG=${cfg.rcloneConfigFile}
          ''
        )
      );

      paths = cfg.paths;
      exclude = cfg.exclude;
      timerConfig = cfg.timerConfig;
      pruneOpts = cfg.pruneOpts;
      initialize = cfg.initialize;
      extraBackupArgs = cfg.extraBackupArgs;
      rcloneOptions = cfg.rcloneOptions;

      createWrapper = true;

      backupPrepareCommand = ''
        echo "Starting Google Drive backup at $(date)"
        echo "Backing up paths: ${concatStringsSep ", " cfg.paths}"
      '';

      backupCleanupCommand = ''
        echo "Google Drive backup completed at $(date)"
      '';
    };
  };
}
