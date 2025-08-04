{ ... }:

{
  programs.plasma.hotkeys.commands = {
    "1password-quick-access" = {
      name = "1Password Quick Access";
      command = "1password --quick-access";
      comment = "Open 1Password Quick Access";
      key = "Ctrl+Shift+Space";
    };
  };

}
