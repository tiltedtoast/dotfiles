{
  config,
  lib,
  ...
}:
{
  systemd.services.link-wslg-runtime = {
    enable = true;
    description = "Symlink all WSLg runtime files";
    wantedBy = [ "multi-user.target" ];
    after = [ "user-runtime-dir@1000.service" ];
    wants = [ "user-runtime-dir@1000.service" ];

    serviceConfig = {
      ExecStartPre = [
        "/run/current-system/sw/bin/ln -sf /mnt/wslg/runtime-dir/pulse /run/user/1000/pulse"
        "/run/current-system/sw/bin/ln -sf /mnt/wslg/runtime-dir/wayland-0 /run/user/1000/wayland-0"
      ];
      ExecStart = "/run/current-system/sw/bin/ln -sf /mnt/wslg/runtime-dir/wayland-0.lock /run/user/1000/wayland-0.lock";
    };
  };
}
