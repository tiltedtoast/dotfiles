{
  inputs,
  pkgs,
  ...
}:

{

  nixpkgs.overlays = [
    (final: prev: {
      kdePackages = inputs.kde-nixpkgs.legacyPackages.x86_64-linux.kdePackages;
    })
  ];

  services = {
    desktopManager.plasma6.enable = true;
    desktopManager.plasma6.enableQt5Integration = false;
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
