{
  pkgs,
  ...
}:

{
  services = {
    desktopManager.plasma6.enable = true;
    displayManager.sddm = {
      enable = true;
      wayland = true;
    };
  };

  environment.systemPackages = with pkgs.kdePackages; [
    kcalc
    kcharselect
    kcolorchooser
    ksystemlog
    sddm-kcm
    pkgs.wl-clipboard
  ];
}
