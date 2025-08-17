{
  pkgs,
  currentUsername,
  config,
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
    ./disko.nix
  ];

  nvidia = {
    cuda.enable = true;
    driver = {
      enable = true;
      package = config.boot.kernelPackages.nvidiaPackages.beta;
    };
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

  nextdns = {
    enable = true;
    configFile = "/home/${currentUsername}/.config/nextdns/resolved.conf";
    hostName = "NixOS--PC";
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

  networking.networkmanager.enable = true;

  services.libinput.enable = true;

  nixpkgs.overlays = [
    (import ../../overlays/rtl8761b-firmware.nix)
  ];

  hardware.firmware = with pkgs; [
    rtl8761b-firmware
  ];

  services.ratbagd.enable = true;

  environment.systemPackages = with pkgs; [
    ghostty
    vscode-fhs
    librewolf
    btrfs-progs

    libratbag
    piper

    xdg-utils
    xdg-desktop-portal
    kdePackages.xdg-desktop-portal-kde

    # Bluetooth Dongle
    rtl8761b-firmware

    (discord.override {
      withVencord = true;
    })
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
  };

  programs.mtr.enable = true;
  system.stateVersion = "25.05";
}
