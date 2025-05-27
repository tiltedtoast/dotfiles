{
  config,
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
in
{
  imports = [
    ../../common/security.nix
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
      unstable.gleam
      git-filter-repo
      unstable.go
      gtk4
      gtk3
      gtk2
      hyperfine
      unstable.jdk24
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
    ];

  hardware.graphics.extraPackages = [
    unstable.pocl
  ];

  nixpkgs.overlays = [
    (final: prev: {
      # mesa = unstable.mesa;
      # libGL = unstable.mesa;
      # libglvnd = unstable.libglvnd;
    })
  ];

  environment.variables = {
    LIBVA_DRIVERS_PATH = "${unstable.mesa}/lib/dri";
    VK_DRIVER_FILES = "${unstable.mesa}/share/vulkan/icd.d/dzn_icd.x86_64.json";
    VK_ICD_FILENAMES = "${unstable.mesa}/share/vulkan/icd.d/dzn_icd.x86_64.json";
    VK_LAYER_PATH = "${unstable.mesa}/share/vulkan/explicit_layer.d";
    LIBGL_DRIVERS_PATH = "${unstable.mesa}/lib/dri";
    OCL_ICD_FILENAMES = "${unstable.pocl}/etc/OpenCL/vendors/pocl.icd";

    JAVA_HOME = "${unstable.jdk24}";

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
  };

  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  programs.nix-ld.enable = true;

  virtualisation.docker.enable = false;

  users.users.tim = {
    isNormalUser = true;
    extraGroups = [ "docker" ];
  };

  system.stateVersion = "24.11";
}
