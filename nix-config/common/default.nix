{
  pkgs,
  ...
}:

{
  imports = [
    ./security.nix
    ./nixpkgs.nix
  ];

  fonts = {
    fontDir.enable = true;

    packages = with pkgs; [
      inter
      nerd-fonts.fira-code
      nerd-fonts.jetbrains-mono
      nerd-fonts.caskaydia-mono
    ];
  };

  time.timeZone = "Europe/Berlin";

  programs.nano = {
    enable = true;
    nanorc = ''
      set tabsize 4
      set tabstospaces
    '';
  };

  services.xserver.xkb = {
    layout = "us";
    variant = "altgr-intl";
  };

  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "de_DE.UTF-8";
      LC_TIME = "C.UTF-8";
      LC_TELEPHONE = "C.UTF-8";
      LC_MEASUREMENT = "C.UTF-8";
      LC_PAPER = "C.UTF-8";
      LC_IDENTIFICATION = "C.UTF-8";
    };
  };

  programs.command-not-found.enable = true;
}
