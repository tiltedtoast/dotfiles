{ pkgs, currentUsername, ... }:

{
  boot.loader = {
    efi.canTouchEfiVariables = true;

    grub = {
      enable = true;
      devices = [ "nodev" ];
      efiSupport = true;
      font = "${pkgs.nerd-fonts.jetbrains-mono}/share/fonts/truetype/NerdFonts/JetBrainsMono/JetBrainsMonoNerdFont-Regular.ttf";
      fontSize = 24;

      extraEntries = ''
        menuentry 'Windows' --class windows --class os {
          search --fs-uuid --set=root 0CF9-FFEE
          chainloader /efi/Microsoft/Boot/bootmgfw.efi
        }
      '';
    };
  };

  users.groups.media = { };

  users.users.sonarr.extraGroups = [ "media" ];
  users.users.qbittorrent.extraGroups = [ "media" ];
  users.users.${currentUsername}.extraGroups = [ "media" ];

  fileSystems."/mnt/shows" = {
    device = "/dev/disk/by-uuid/206C11B36C1184A6";
    fsType = "ntfs3";
    options = [
      "defaults"
      "uid=1000"
      "gid=media"
      "umask=0002"
      "rw"
    ];
  };

  fileSystems."/mnt/games" = {
    device = "/dev/disk/by-uuid/1260ED5460ED3F5B";
    fsType = "ntfs3";
    options = [
      "defaults"
      "uid=1000"
      "gid=media"
      "umask=0002"
      "rw"
    ];
  };

  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/disk/by-partlabel/disk-main-root";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "btrfs";
            extraArgs = [ "-f" ];
            subvolumes = {
              "/root" = {
                mountpoint = "/";
                mountOptions = [
                  "compress=zstd"
                  "noatime"
                ];
              };
              "/home" = {
                mountpoint = "/home";
                mountOptions = [
                  "compress=zstd"
                  "noatime"
                ];
              };
              "/nix" = {
                mountpoint = "/nix";
                mountOptions = [
                  "compress=zstd"
                  "noatime"
                ];
              };
              "/swap" = {
                mountpoint = "/swap";
                swap.swapfile.size = "70G";
              };
            };
          };
        };
      };
    };
  };
}
