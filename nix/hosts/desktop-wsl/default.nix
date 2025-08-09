{ pkgs, currentUsername, ... }:

{
  imports = [
    ./services.nix
    ../../common
    ../../modules/system/nvidia.nix
  ];

  networking.hostName = "nixos-wsl-pc";
  nvidia.cuda.enable = true;

  environment.systemPackages = [
    (pkgs.callPackage ../../pkgs/wsl2-ssh-agent.nix { })
  ];

  environment.variables = {
    LIBVA_DRIVERS_PATH = "${pkgs.mesa}/lib/dri";
    VK_DRIVER_FILES = "${pkgs.mesa}/share/vulkan/icd.d/dzn_icd.x86_64.json";
    VK_ICD_FILENAMES = "${pkgs.mesa}/share/vulkan/icd.d/dzn_icd.x86_64.json";
    VK_LAYER_PATH = "${pkgs.mesa}/share/vulkan/explicit_layer.d";
    LIBGL_DRIVERS_PATH = "${pkgs.mesa}/lib/dri";

    JAVA_HOME = "${pkgs.jdk}";

    LD_LIBRARY_PATH = [
      "${pkgs.stdenv.cc.cc.lib}/lib"
      "${pkgs.llvmPackages_20.libcxx}/lib"
      "${pkgs.llvmPackages_20.libunwind}/lib"
    ];

    CPATH = [
      "${pkgs.libglvnd.dev}/include"
    ];

    PKG_CONFIG_PATH = [
      "${pkgs.openssl.dev}/lib/pkgconfig"
    ];

    SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt";
  };

  virtualisation.docker.enable = false;

  users.users.${currentUsername} = {
    isNormalUser = true;
    extraGroups = [
      "docker"
      "wheel"
      "networkmanager"
      "video"
      "render"
    ];
  };

  wsl = {
    enable = true;
    defaultUser = currentUsername;
    wslConf.interop.appendWindowsPath = false;
  };

  system.stateVersion = "24.11";
}
