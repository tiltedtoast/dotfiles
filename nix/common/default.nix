{
  pkgs,
  currentUsername,
  config,
  ...
}:

{
  imports = [
    ./security.nix
    ./packages.nix
  ];

  nixpkgs.config = {
    allowUnfree = true;
    permittedInsecurePackages = [
      "olm-3.2.16"
    ];
  };

  age.identityPaths = [
    "/home/${currentUsername}/.config/age/key"
    "/root/.config/age/key"
    "/etc/age/key"
  ];

  nix.settings = {
    substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://cache.flox.dev"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs="
    ];
  };

  fonts = {
    fontDir.enable = true;

    packages = with pkgs; [
      inter
      nerd-fonts.fira-code
      nerd-fonts.jetbrains-mono
      nerd-fonts.caskaydia-mono
      noto-fonts-cjk-sans
    ];
  };

  age.secrets = {
    hashed-password.file = ../secrets/hashed-password.age;
  };

  users.users.${currentUsername} = {
    isNormalUser = true;
    extraGroups = [
      "docker"
      "wheel"
      "networkmanager"
      "audio"
      "video"
      "render"
      "input"
      "gamemode"
      "wireshark"
    ];
    hashedPasswordFile = config.age.secrets.hashed-password.path;
  };

  programs.wireshark = {
    package = pkgs.wireshark-qt;
    enable = true;
    usbmon.enable = true;
  };

  time.timeZone = "Europe/Berlin";

  environment.variables = {
    SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt";
  };

  environment.sessionVariables.NH_FLAKE = "$HOME/dotfiles/nix";

  environment.shellAliases = {
    nix-shell = "nix-shell --command zsh";

    nixos-switch = "nh os switch -- --impure";
    nixos-boot = "nh os boot -- --impure";

    flake-update = "sudo nix flake update --flake $NH_FLAKE";
    update = "nh os switch --update -- --impure";
  };

  environment.interactiveShellInit = ''
    flake-template() {
      nix flake init --template $NH_FLAKE#$1
    }
  '';

  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  programs.nix-ld.enable = true;

  nix.settings = {
    trusted-users = [
      currentUsername
      "root"
    ];
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  nixpkgs.config.freetype = {
    withHarfbuzz = true;
    withGnuByteCode = true;
  };

  programs.nh.enable = true;
  programs.direnv.enable = true;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  programs.nano = {
    enable = true;
    nanorc = ''
      set tabsize 4
      set tabstospaces
    '';
  };

  services.xserver.xkb = {
    layout = "us,de";
    variant = "altgr-intl,";
  };

  console.useXkbConfig = true;

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

  programs.nix-index-database.comma.enable = true;
  programs.nix-index.enableBashIntegration = true;
  programs.nix-index.enableZshIntegration = true;
}
