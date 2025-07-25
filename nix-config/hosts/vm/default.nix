{
  pkgs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ../../common
    ../../modules/kde.nix
    ../../modules/1password.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  networking.hostName = "nixos-vm";

  xdg.mime.defaultApplications = {
    "text/html" = "librewolf.desktop";
    "x-scheme-handler/http" = "librewolf.desktop";
    "x-scheme-handler/https" = "librewolf.desktop";
    "x-scheme-handler/about" = "librewolf.desktop";
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.networkmanager.enable = true;

  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  services.libinput.enable = true;

  users.users.tim = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
  };

  environment.systemPackages = with pkgs; [
    wget
    ghostty
    mesa
    mesa-demos
    moar
    eza
    bat
    fastfetch
    git
    oh-my-posh
    chezmoi
    btop
    vscode-fhs
    librewolf
    ripgrep
    fd
    xdg-utils
    xdg-desktop-portal
    xdg-desktop-portal-gtk
    file
    atuin
    nixd
    unzip
    nixfmt-rfc-style
    delta
    gh
    ookla-speedtest
  ];

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  environment.variables = {
    BROWSER = "${pkgs.librewolf}/bin/librewolf";
    DEFAULT_BROWSER = "${pkgs.librewolf}/bin/librewolf";
  };

  programs.mtr.enable = true;
  system.stateVersion = "25.05";

}
