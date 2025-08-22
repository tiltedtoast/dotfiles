{ pkgs, ... }:
{

  programs.steam = {
    enable = true;
    extraCompatPackages = with pkgs; [
      proton-ge-bin
    ];
  };

  programs.gamescope.enable = true;

  programs.gamemode.enable = true;
  environment.systemPackages = with pkgs; [
    wineWowPackages.stable
    mangohud
    protonup-qt
    lutris
    bottles
    # heroic
    winetricks
  ];
}
