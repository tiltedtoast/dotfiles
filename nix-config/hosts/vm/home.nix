{
  pkgs,
  ...
}:

{
  home.stateVersion = "25.11";

  imports = [
    ../../modules/home/1password.nix
  ];

  programs.plasma = {
    enable = true;
    overrideConfig = true;

    workspace = {
      lookAndFeel = "org.kde.breezedark.desktop";
      wallpaper = "${pkgs.kdePackages.plasma-workspace-wallpapers}/share/wallpapers/MilkyWay/contents/images/1080x1920.png";
    };

    fonts = {
      general = {
        family = "Inter";
        pointSize = 10;
      };

      fixedWidth = {
        family = "ComicCodeLigatures Nerd Font Mono";
        pointSize = 10;
      };
    };
  };
}
