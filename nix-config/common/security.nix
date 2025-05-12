{
  config,
  lib,
  ...
}:

{
  security.sudo = {
    enable = true;
    extraRules = [
      {
        users = [ "tim" ];
        commands = [ "ALL" ];
      }
      {
        users = [ "tim" ];
        commands = [
          {
            command = "/run/current-system/sw/bin/ip";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/ln";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];
  };
}
