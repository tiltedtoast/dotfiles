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
