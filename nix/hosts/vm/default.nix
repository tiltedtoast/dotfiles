{
  pkgs,
  globalOptions,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ../../common
    ../../modules/system/kde.nix
    ../../modules/system/1password.nix
    ../../modules/system/luks-btrfs-disko.nix
    ../../modules/system/pipewire.nix
  ];

  services.disk = {
    enable = true;
    disk = "/dev/sda";
    swapSize = "18G";
  };

  audio = {
    enable = true;
    input = "alsa_input.pci-0000_02_02.0.analog-stereo";
    output = "alsa_output.pci-0000_02_02.0.analog-stereo";

    mic_process = {
      enable = true;
      vad_threshold = 50.0;
    };

    eq = {
      enable = true;
      preamp = -6.0;
      settings = [
        {
          freq = 42;
          gain = 7.3;
        }
        {
          freq = 143;
          gain = -5.0;
        }
        {
          freq = 1524;
          gain = -3.8;
        }
        {
          freq = 3845;
          gain = -9.9;
        }
        {
          freq = 6520;
          gain = 7.8;
        }
        {
          freq = 2492;
          gain = 2.0;
        }
        {
          freq = 3108;
          gain = -2.5;
        }
        {
          freq = 4006;
          gain = 2.1;
        }
        {
          freq = 4816;
          gain = -1.3;
        }
        {
          freq = 6050;
          gain = 1.2;
        }
      ];
    };
  };

  networking.hostName = "nixos-vm";

  xdg.mime.defaultApplications = {
    "text/html" = "librewolf.desktop";
    "x-scheme-handler/http" = "librewolf.desktop";
    "x-scheme-handler/https" = "librewolf.desktop";
    "x-scheme-handler/about" = "librewolf.desktop";
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.networkmanager.enable = true;

  services.libinput.enable = true;

  users.users.${globalOptions.username} = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "audio"
    ];
  };

  environment.systemPackages = with pkgs; [
    ghostty
    vscode-fhs
    librewolf

    xdg-utils
    xdg-desktop-portal
    xdg-desktop-portal-gtk
  ];

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  environment.variables = {
    BROWSER = "${pkgs.librewolf}/bin/librewolf";
    DEFAULT_BROWSER = "${pkgs.librewolf}/bin/librewolf";

    NIXOS_OZONE_WL = "1";
  };

  programs.mtr.enable = true;
  system.stateVersion = "25.05";
}
