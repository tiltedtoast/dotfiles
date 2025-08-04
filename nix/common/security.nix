{ globalOptions, ... }:

{
  security.sudo = {
    enable = true;
    extraRules = [
      {
        users = [ globalOptions.username ];
        commands = [ "ALL" ];
      }
      {
        users = [ globalOptions.username ];
        commands = [
          {
            command = "/run/current-system/sw/bin/ip";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];
  };
}
