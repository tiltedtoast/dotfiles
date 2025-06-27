{
  lib,
  inputs,
  ...
}:

let
  unstable = import inputs.nixpkgs-unstable {
    system = "x86_64-linux";
    config.allowUnfree = true;
  };
  pkgs = import inputs.nixpkgs {
    system = "x86_64-linux";
    config.allowUnfree = true;
  };

  pocl-cuda = import ../../pkgs/pocl { inherit unstable lib; };
in
{
  imports = [
    ../../common
    ./services.nix
  ];

  nix.settings.trusted-users = [
    "root"
    "tim"
  ];
  networking.hostName = "nixos-wsl";
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  environment.systemPackages =
    with pkgs;
    with unstable.llvmPackages_20;
    with unstable.cudaPackages;
    [
      cachix
      file
      unstable.gcc
      unstable.moar
      unstable.dust
      rm-improved
      wget
      gnumake
      ninja
      git
      unstable.btop
      delta
      unzip
      zsh
      stow
      curl
      cmake
      imagemagick
      gifsicle
      openssh
      openssl
      unstable.oh-my-posh
      fzf
      atuin
      unstable.bun
      zoxide
      gh
      rustup
      unstable.uv
      ookla-speedtest
      unstable.mold
      sqlite
      containerd
      unstable.fastfetch
      openssl
      pkg-config
      direnv
      git-filter-repo
      unstable.go
      gtk4
      gtk3
      gtk2
      hyperfine
      unstable.jdk
      jq
      kmod
      lz4
      maven
      gradle
      musl
      unstable.oha
      unstable.protobuf
      unstable.qemu
      valgrind
      wl-clipboard
      hex
      unstable.nixfmt-rfc-style
      unstable.mpi
      unstable.mpi.dev
      age

      clang-tools
      clang-manpages
      openmp
      clangUseLLVM
      bintools-unwrapped

      unstable.bear
      unstable.tokei
      unstable.eza
      unstable.bat
      ripgrep
      fd
      unstable.vulkan-tools
      libva-utils
      vdpauinfo
      unstable.mesa-demos
      unstable.vulkan-loader
      sd

      cuda_gdb
      libcublas
      cuda_nvcc
      tensorrt
      cuda_opencl
      cuda_nvtx
      cuda_nvrtc
      cuda_nvprof
      cuda_cupti
      cuda_cccl
      cuda_cudart
      cudatoolkit

      unstable.ffmpeg-full
      unstable.nixd
      docker
      turso-cli
      clinfo
      opencl-headers
      unstable.mesa
      unstable.libgcc
      volta

      (pkgs.callPackage ../../pkgs/wsl2-ssh-agent/default.nix { })
    ];

  hardware.graphics.extraPackages = [
    pocl-cuda
  ];

  nixpkgs.overlays = [
    (final: prev: {
      # mesa = unstable.mesa;
      # libGL = unstable.mesa;
      # libglvnd = unstable.libglvnd;
    })
  ];

  programs.direnv.enable = true;

  environment.variables = {
    LIBVA_DRIVERS_PATH = "${unstable.mesa}/lib/dri";
    VK_DRIVER_FILES = "${unstable.mesa}/share/vulkan/icd.d/dzn_icd.x86_64.json";
    VK_ICD_FILENAMES = "${unstable.mesa}/share/vulkan/icd.d/dzn_icd.x86_64.json";
    VK_LAYER_PATH = "${unstable.mesa}/share/vulkan/explicit_layer.d";
    LIBGL_DRIVERS_PATH = "${unstable.mesa}/lib/dri";
    OCL_ICD_FILENAMES = "${pocl-cuda}/etc/OpenCL/vendors/pocl.icd";

    JAVA_HOME = "${unstable.jdk}";

    LD_LIBRARY_PATH = [
      "${unstable.stdenv.cc.cc.lib}/lib"
      "${unstable.cudatoolkit}/lib"
      "${unstable.cudaPackages.cuda_cudart.static}/lib"
      "${unstable.llvmPackages_20.libcxx}/lib"
      "${unstable.llvmPackages_20.libunwind}/lib"
    ];

    CPATH = [
      "${unstable.cudatoolkit}/include"
      "${unstable.libglvnd.dev}/include"
    ];

    PKG_CONFIG_PATH = [
      "${pkgs.openssl.dev}/lib/pkgconfig"
    ];

    SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt";

    CUDA_PATH = "${unstable.cudatoolkit}";
    CUDA_ROOT = "${unstable.cudatoolkit}";

    NH_FLAKE = "/home/tim/dotfiles/nix-config";
  };

  environment.shellAliases = {
    # Thanks for trying to access /run/current-system/sw/bin/../nvvm/bin/cicc
    nvcc = "${unstable.cudaPackages.cudatoolkit}/bin/nvcc";

    nix-shell = "nix-shell --command zsh";
  };

  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  programs.nix-ld.enable = true;

  virtualisation.docker.enable = false;

  users.users.tim = {
    isNormalUser = true;
    extraGroups = [
      "docker"
      "wheel"
      "networkmanager"
      "video"
      "render"
    ];
  };

  programs.nh = {
    enable = true;
    #clean.enable = true;
    #clean.extraArgs = "--keep-since 4d --keep 3";
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  wsl = {
    enable = true;
    defaultUser = "tim";
    wslConf.interop.appendWindowsPath = false;
  };

  system.stateVersion = "24.11";
}
