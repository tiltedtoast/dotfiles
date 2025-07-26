{ pkgs, ... }:

{
  imports = [
    ./services.nix
    ../../common
    ../../modules/system/nvidia.nix
  ];

  networking.hostName = "nixos-wsl-pc";
  nvidia.cuda.enable = true;

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
    pixi

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

  wsl = {
    enable = true;
    defaultUser = "tim";
    wslConf.interop.appendWindowsPath = false;
  };

  system.stateVersion = "24.11";
}
