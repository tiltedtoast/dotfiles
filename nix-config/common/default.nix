{
  pkgs,
  ...
}:

{
  imports = [
    ./security.nix
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

}
