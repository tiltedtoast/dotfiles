{ currentUsername, ... }:

{
  security.polkit.enable = true;

  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ currentUsername ];
  };

  # Idk if this is really worth it
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (
        (
          action.id == "com.1password.1Password.unlock" ||
          action.id == "com.1password.1Password.authorizeSshAgent"
        ) &&
        subject.user == "${currentUsername}"
      ) {
        return polkit.Result.YES;
      }
    });
  '';

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
