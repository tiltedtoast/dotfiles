{
  pkgs,
  ...
}:

{
  services = {
    desktopManager.plasma6.enable = true;
    displayManager.sddm = {
      enable = true;
      wayland.enable = true;
    };
  };

  programs.kdeconnect.enable = true;

  environment.systemPackages = with pkgs.kdePackages; [
    kcalc
    kcharselect
    kcolorchooser
    ksystemlog
    sddm-kcm
    pkgs.wayland-utils
    pkgs.wl-clipboard
    kdeconnect-kde

    kaccounts-integration
    kaccounts-providers
    kio-gdrive

    signond
    signon-kwallet-extension
    kdepim-addons
  ];

}
