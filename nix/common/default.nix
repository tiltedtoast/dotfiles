{
  pkgs,
  globalOptions,
  ...
}:

{
  imports = [
    ./security.nix
    ./packages.nix
  ];

  nixpkgs.config.allowUnfree = true;

  fonts = {
    fontDir.enable = true;

    packages = with pkgs; [
      inter
      nerd-fonts.fira-code
      nerd-fonts.jetbrains-mono
      nerd-fonts.caskaydia-mono
    ];
  };

    users.users.${globalOptions.username} = {
    isNormalUser = true;
    extraGroups = [
      "docker"
      "wheel"
      "networkmanager"
      "audio"
      "video"
      "render"
    ];
    initialPassword = "password"; # Obviously change this asap
  };

  time.timeZone = "Europe/Berlin";

  environment.sessionVariables.NH_FLAKE = "$HOME/dotfiles/nix";

  environment.shellAliases = {
    nix-shell = "nix-shell --command zsh";
    nixos-switch = "nh os switch";
    flake-update = "sudo nix flake update --flake $NH_FLAKE";
    update = "nh os switch --update";
  };

  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  programs.nix-ld.enable = true;

  nix.settings = {
    trusted-users = [
      globalOptions.username
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
  programs.nix-index-database.comma.enable = true;
  programs.nix-index.enableBashIntegration = false;
  programs.nix-index.enableZshIntegration = false;
}
