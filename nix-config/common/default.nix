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

  environment.sessionVariables.NH_FLAKE = "$HOME/dotfiles/nix-config";

  environment.shellAliases = {
    nix-shell = "nix-shell --command zsh";
  };

  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  programs.nix-ld.enable = true;

  nix.settings = {
    trusted-users = [
      "tim"
      "root"
    ];
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  programs.nh.enable = true;
  programs.direnv.enable = true;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

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
