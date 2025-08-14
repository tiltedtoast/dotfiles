{
  config,
  lib,
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
  ];
  boot.extraModulePackages = [ ];

  boot.kernelParams = [ "resume_offset=533760" ];
  boot.resumeDevice = "/dev/disk/by-partlabel/disk-main-root";

  powerManagement.enable = true;

  hardware.nvidia.powerManagement.enable = true;

  swapDevices = [
    {
      device = "/swap/swapfile";
      size = 70 * 1024; # 70GB
    }
  ];

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
