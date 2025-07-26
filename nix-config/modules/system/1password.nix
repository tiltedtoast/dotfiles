{ ... }:

{
  security.polkit.enable = true;

  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "tim" ];
  };

  environment.etc = {
    "1password/custom_allowed_browsers" = {
      text = ''
        librewolf
        librewolf-bin
        .librewolf-wrapped
        .librewolf-wrap
      '';
      mode = "0755";
    };
  };

  environment.sessionVariables = {
    SSH_AUTH_SOCK = "$HOME/.1password/agent.sock";
  };

  environment.etc."xdg/autostart/1password.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=1Password
    Exec=1password --silent
    Hidden=false
    NoDisplay=false
    X-GNOME-Autostart-enabled=true
  '';
}
