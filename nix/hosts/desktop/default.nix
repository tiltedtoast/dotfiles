{
  pkgs,
  currentUsername,
  config,
  inputs,
  lib,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ../../common
    ../../modules/system/kde.nix
    ../../modules/system/1password.nix
    ../../modules/system/pipewire.nix
    ../../modules/system/spicetify.nix
    ../../modules/system/nvidia.nix
    ../../modules/system/nextdns.nix
    ../../modules/system/disable-wakeup.nix
    ../../modules/system/gaming.nix
    ../../modules/system/qbittorrent.nix
    ../../modules/system/openrgb.nix
    ../../modules/system/vpn-run.nix
    ../../modules/system/hdr.nix
    ./disko.nix
  ];

  age.secrets = {
    restic-password.file = ../../secrets/restic-password.age;
    "nextdns-resolved.conf".file = ../../secrets/nextdns-resolved.conf.age;
  };

  virtualisation.libvirtd = {
    enable = true;
    qemu.vhostUserPackages = with pkgs; [ virtiofsd ];
  };

  programs.virt-manager.enable = true;

  nvidia = {
    cuda.enable = true;
    driver = {
      enable = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
  };

  hdr = {
    enable = true;
    defaultOutput = "DP-3";
    extraScripts = true;
  };

  fileSystems."/mnt/gdrive" = {
    device = "gdrive:";
    fsType = "rclone";
    options = [
      "nodev"
      "nofail"
      "allow_other"
      "args2env"
      "vfs-cache-mode=full"
      "config=/home/${currentUsername}/.config/rclone/rclone.conf"
    ];
  };

  services.restic.backups.gdrive = {
    repository = "rclone:gdrive:backups/desktop";
    passwordFile = config.age.secrets.restic-password.path;

    paths = [
      "/home/${currentUsername}/Documents"
      "/home/${currentUsername}/Pictures"
      "/home/${currentUsername}/Videos"
      "/home/${currentUsername}/Music"
      "/home/${currentUsername}/.librewolf/f9ugjznf.default/user.js"
      "/home/${currentUsername}/.librewolf/f9ugjznf.default/cookies.sqlite"
      "/home/${currentUsername}/.librewolf/f9ugjznf.default/cookies.sqlite-wal"
      "/home/${currentUsername}/.librewolf/f9ugjznf.default/places.sqlite"
      "/home/${currentUsername}/.librewolf/f9ugjznf.default/chrome"
      "/var/lib/sonarr/.config/NzbDrone/Backups"
      "/var/lib/private/prowlarr/Backups"
      "/home/${currentUsername}/.var/app/com.core447.StreamController"
    ];
    exclude = [
      "*.tmp"
      ".cache"
      "*.log"
      "node_modules"
      "/home/${currentUsername}/Documents/NVIDIA Nsight Compute"
      "/home/${currentUsername}/Documents/NVIDIA Nsight Systems"
    ];

    environmentFile = toString (
      pkgs.writeText "gdrive-rclone-env" ''
        RCLONE_CONFIG=/home/${currentUsername}/.config/rclone/rclone.conf
      ''
    );

    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };

    pruneOpts = [
      "--keep-daily 4"
      "--keep-weekly 3"
      "--keep-monthly 2"
    ];

    initialize = true;

    rcloneOptions = {
      drive-use-trash = false;
    };

    createWrapper = true;

    backupPrepareCommand = ''
      echo "Starting Google Drive backup at $(date)"
      echo "Backing up paths: ${lib.concatStringsSep ", " config.services.restic.backups.gdrive.paths}"
    '';

    backupCleanupCommand = ''
      echo "Google Drive backup completed at $(date)"
    '';
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  services.printing = {
    enable = true;
    drivers = with pkgs; [
      cups-filters
      cups-browsed
    ];
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = true;
      };
    };
  };

  qbittorrent = {
    enable = true;
    wireguard.interface = "wg0";
    webui = {
      port = 8080;
      username = "admin";
      hashedPassword = "@ByteArray(ld9tpxX1BfxpzgEImGXLJA==:yxC2mw6+EfF14jJNV9ppuS0sqNas7ENWXAccUu+gCVNP0h7NokJA1dgnkoWejmDfp5mq6OEFXEHPGkLJNUZNiw==)";
    };
  };

  networking.wireguard.interfaces = {
    wg0 = {
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
  };

  services.sonarr = {
    enable = true;
    openFirewall = true;
  };

  services.prowlarr = {
    enable = true;
    openFirewall = true;
  };

  services.flaresolverr = {
    enable = true;
    openFirewall = true;
  };

  nextdns = {
    enable = true;
    configFile = config.age.secrets."nextdns-resolved.conf".path;
    hostName = "NixOS--PC";
  };

  vpn-run = {
    enable = true;
    defaultInterface = "wg0";
    allowedUsers = [ currentUsername ];
  };

  programs.streamcontroller.enable = true;

  services.udev.extraRules = ''
    # StreamController text input
    KERNEL=="uinput", SUBSYSTEM=="misc", OPTIONS+="static_node=uinput", TAG+="uaccess", GROUP="input", MODE="0660"
  '';

  disableWakeFromHibernate.enable = true;

  virtualisation.docker.enable = true;
  hardware.nvidia-container-toolkit.enable = true;

  audio = {
    enable = true;
    input = "alsa_input.pci-0000_0b_00.4.analog-stereo";
    output = "alsa_output.usb-Schiit_Audio_Schiit_Modi_Uber-00.analog-stereo";

    micProcess = {
      enable = true;
      vadThreshold = 50.0;

      compressor = {
        attackTime = 10.6;
        releaseTime = 500;
        threshold = -18.3;
        ratio = 4.0;
        makeupGain = 5.9;
      };
    };

    eq = {
      enable = true;
      file = "/home/${currentUsername}/.local/share/auto_eq/hd6xx_he-1_parametric.txt";
    };

    appCategories = {
      Browser.appNames = [ "LibreWolf" ];
      Music = {
        limitThreshold = -12.0;
        appNames = [
          "spotify"
          "foobar2000 Application"
        ];
      };
      Discord.appNames = [
        "Discord.*"
        "Slack.*"
      ];
      System = { };
    };

    fallbackCategory = "System";
  };

  networking.hostName = "nixos-pc";

  xdg.mime.defaultApplications = {
    "text/html" = "librewolf.desktop";
    "x-scheme-handler/http" = "librewolf.desktop";
    "x-scheme-handler/https" = "librewolf.desktop";
    "x-scheme-handler/about" = "librewolf.desktop";
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.networkmanager = {
    enable = true;
    plugins = [
      pkgs.networkmanager-strongswan
    ];
  };

  environment.etc."strongswan.conf".text = ''
    charon-nm { plugins { eap-peap { load = no } } }
  '';

  services.libinput.enable = true;

  services.btrfs.autoScrub = {
    enable = true;
    interval = "weekly";
    fileSystems = [ "/" ];
  };

  nixpkgs.overlays = [
    (import ../../overlays/rtl8761b-firmware.nix)
  ];

  hardware.firmware = with pkgs; [
    rtl8761b-firmware
  ];

  services.ratbagd.enable = true;

  programs.thunderbird.enable = true;

  environment.systemPackages = with pkgs; [
    ghostty
    vscode-fhs
    zed-editor-fhs
    btrfs-progs
    mpv
    librewolf

    inputs.agenix.packages."${pkgs.system}".default

    libratbag
    piper
    vlc
    libnotify
    ghidra
    teams-for-linux
    libreoffice-qt6
    nheko

    xdg-utils
    xdg-desktop-portal
    kdePackages.xdg-desktop-portal-kde

    # Bluetooth Dongle
    rtl8761b-firmware

    (discord.override {
      withVencord = true;
    })

    (pkgs.callPackage ../../pkgs/hayase.nix { })
  ];

  hardware.logitech.wireless = {
    enable = true;
    enableGraphical = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.kdePackages.xdg-desktop-portal-kde ];
  };

  environment.variables = {
    BROWSER = "${pkgs.librewolf}/bin/librewolf";
    DEFAULT_BROWSER = "${pkgs.librewolf}/bin/librewolf";

    VK_DRIVER_FILES = "/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.x86_64.json";
    VK_ICD_FILENAMES = "/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.x86_64.json";

    NIXOS_OZONE_WL = "1";

    # hardware acceleration results in a segfault + dmabuf/WL error
    MOZ_ENABLE_WAYLAND = 0;
    MOZ_DISABLE_RDD_SANDBOX = 1;
    GHIDRA_ROOT = "${pkgs.ghidra}";
  };

  programs.mtr.enable = true;
  system.stateVersion = "25.05";
}
