{ pkgs, ... }:

{
  imports = [
    ../../common
    ./services.nix
  ];

  nix.settings.trusted-users = [
    "root"
    "tim"
  ];
  networking.hostName = "nixos-wsl-pc";
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nixpkgs.overlays = [
    (import ../../overlays/pocl-cuda.nix)
  ];

  environment.systemPackages = with pkgs; [
    cachix
    file
    gcc
    moar
    dust
    rm-improved
    wget
    gnumake
    ninja
    git
    btop
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
    oh-my-posh
    fzf
    atuin
    bun
    zoxide
    gh
    rustup
    uv
    ookla-speedtest
    mold
    sqlite
    containerd
    fastfetch
    openssl
    pkg-config
    direnv
    git-filter-repo
    go
    gtk4
    gtk3
    gtk2
    hyperfine
    jdk
    jq
    kmod
    lz4
    maven
    gradle
    musl
    oha
    protobuf
    qemu
    valgrind
    wl-clipboard
    hex
    nixfmt-rfc-style
    mpi
    mpi.dev
    age
    chezmoi

    llvmPackages_20.clang-tools
    llvmPackages_20.clang-manpages
    llvmPackages_20.openmp
    llvmPackages_20.clangUseLLVM
    llvmPackages_20.bintools-unwrapped

    bear
    tokei
    eza
    bat
    ripgrep
    fd
    vulkan-tools
    libva-utils
    vdpauinfo
    mesa-demos
    vulkan-loader
    sd

    cudaPackages.libcublas
    cudaPackages.cuda_gdb
    cudaPackages.cuda_nvcc
    cudaPackages.cuda_opencl
    cudaPackages.cuda_nvtx
    cudaPackages.cuda_nvrtc
    cudaPackages.cuda_nvprof
    cudaPackages.cuda_cupti
    cudaPackages.cuda_cccl
    cudaPackages.cuda_cudart
    cudaPackages.cudatoolkit

    ffmpeg-full
    nixd
    docker
    turso-cli
    clinfo
    opencl-headers
    mesa
    libgcc
    volta
    python3Full

    (pkgs.callPackage ../../pkgs/wsl2-ssh-agent.nix { })
  ];

  hardware.graphics.extraPackages = [
    pkgs.pocl-cuda
  ];

  programs.direnv.enable = true;

  environment.variables = {
    LIBVA_DRIVERS_PATH = "${pkgs.mesa}/lib/dri";
    VK_DRIVER_FILES = "${pkgs.mesa}/share/vulkan/icd.d/dzn_icd.x86_64.json";
    VK_ICD_FILENAMES = "${pkgs.mesa}/share/vulkan/icd.d/dzn_icd.x86_64.json";
    VK_LAYER_PATH = "${pkgs.mesa}/share/vulkan/explicit_layer.d";
    LIBGL_DRIVERS_PATH = "${pkgs.mesa}/lib/dri";
    OCL_ICD_FILENAMES = "${pkgs.pocl-cuda}/etc/OpenCL/vendors/pocl.icd";

    JAVA_HOME = "${pkgs.jdk}";

    LD_LIBRARY_PATH = [
      "${pkgs.stdenv.cc.cc.lib}/lib"
      "${pkgs.cudatoolkit}/lib"
      "${pkgs.cudaPackages.cuda_cudart.static}/lib"
      "${pkgs.llvmPackages_20.libcxx}/lib"
      "${pkgs.llvmPackages_20.libunwind}/lib"
    ];

    CPATH = [
      "${pkgs.cudatoolkit}/include"
      "${pkgs.libglvnd.dev}/include"
    ];

    PKG_CONFIG_PATH = [
      "${pkgs.openssl.dev}/lib/pkgconfig"
    ];

    SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt";

    CUDA_PATH = "${pkgs.cudatoolkit}";
    CUDA_ROOT = "${pkgs.cudatoolkit}";

    NH_FLAKE = "/home/tim/dotfiles/nix-config";
  };

  environment.shellAliases = {
    # Thanks for trying to access /run/current-system/sw/bin/../nvvm/bin/cicc
    nvcc = "${pkgs.cudaPackages.cudatoolkit}/bin/nvcc";

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
