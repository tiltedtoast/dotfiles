{
  config,
  lib,
  pkgs,
  ...
}:

{
  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [
    "kvm-amd"
    "hid-logitech-dj"
    "zenpower"
  ];

  boot.blacklistedKernelModules = [ "k10temp" ];
  boot.extraModulePackages = [ config.boot.kernelPackages.zenpower ];

  boot.kernelParams = [
    "resume_offset=33307031"
    "drm.edid_firmware=DP-3:edid/odyssey-g7-8bpc.bin"
    "amd_pstate=active"
  ];
  boot.resumeDevice = "/dev/disk/by-partlabel/disk-primary-root";

  powerManagement.enable = true;

  hardware.nvidia.powerManagement.enable = true;

  hardware.firmware = [
    (pkgs.runCommandNoCC "firmware-custom-edid" { } ''
      mkdir -p $out/lib/firmware/edid/
      cp "${../../firmware/odyssey-g7-8bpc-edid.bin}" $out/lib/firmware/edid/odyssey-g7-8bpc.bin
    '')
  ];

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
