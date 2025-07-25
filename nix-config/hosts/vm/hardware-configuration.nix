{ lib, ... }:

{
  imports = [ ];

  boot.initrd.availableKernelModules = [ "ata_piix" "mptspi" "uhci_hcd" "ehci_pci" "ahci" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/09983015-382c-4909-980a-8e0f31bdf1d0";
      fsType = "btrfs";
      options = [ "subvol=root" "compress=zstd" ];
    };

  boot.initrd.luks.devices."crypted".device = "/dev/disk/by-uuid/2d414bad-ed68-4020-b703-a337c649502b";

  fileSystems."/.swapvol" =
    { device = "/dev/disk/by-uuid/09983015-382c-4909-980a-8e0f31bdf1d0";
      fsType = "btrfs";
      options = [ "subvol=swap" "noatime" ];
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/D241-42C0";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };

  fileSystems."/home" =
    { device = "/dev/disk/by-uuid/09983015-382c-4909-980a-8e0f31bdf1d0";
      fsType = "btrfs";
      options = [ "subvol=home" "compress=zstd" ];
    };

  fileSystems."/nix" =
    { device = "/dev/disk/by-uuid/09983015-382c-4909-980a-8e0f31bdf1d0";
      fsType = "btrfs";
      options = [ "subvol=nix" "noatime" ];
    };

  swapDevices = [ ];

  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
