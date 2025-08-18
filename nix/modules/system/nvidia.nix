{
  pkgs,
  config,
  lib,
  ...
}:

with lib;

let
  cfg = config.nvidia;
in
{
  options.nvidia = {
    cuda = mkOption {
      type = types.submodule {
        options = {
          enable = mkEnableOption "CUDA support";
          packages = mkOption {
            type = types.attrsOf types.package;
            default = pkgs.cudaPackages;
            description = "The CUDA packages to use. Defaults to the latest CUDA packages provided by Nixpkgs";
          };
        };
      };
      default = { };
      description = "CUDA configuration";
    };

    driver = mkOption {
      type = types.submodule {
        options = {
          enable = mkEnableOption "NVIDIA graphics driver";
          package = mkOption {
            type = types.package;
            default = config.boot.kernelPackages.nvidiaPackages.stable;
            description = "The NVIDIA driver package to use";
          };
        };
      };
      default = { };
      description = "NVIDIA driver configuration";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.cuda.enable || cfg.driver.enable) {
      hardware.graphics = {
        enable = true;
      };
    })

    # CUDA configuration
    (lib.mkIf cfg.cuda.enable {
      nixpkgs.overlays = [
        (import ../../overlays/pocl-cuda.nix)
      ];
      hardware.graphics.extraPackages = [
        pkgs.pocl-cuda
      ];

      environment.variables = with cfg.cuda.packages; {
        OCL_ICD_FILENAMES = "${pkgs.pocl-cuda}/etc/OpenCL/vendors/pocl.icd";
        CUDA_PATH = "${cudatoolkit}";
        CUDA_ROOT = "${cudatoolkit}";
        CPATH = [
          "${cudatoolkit}/include"
        ];
      };

      environment.shellAliases = {
        # Thanks for trying to access /run/current-system/sw/bin/../nvvm/bin/cicc
        nvcc = "${cfg.cuda.packages.cudatoolkit}/bin/nvcc";
      };

      environment.systemPackages = with cfg.cuda.packages; [
        libcublas
        cuda_gdb
        cuda_nvcc
        cuda_opencl
        cuda_nvtx
        cuda_nvrtc
        cuda_nvprof
        cuda_cupti
        cuda_cccl
        cuda_cudart
        cudatoolkit
        pkgs.nvtopPackages.nvidia
      ];
    })

    # NVIDIA driver configuration
    (lib.mkIf cfg.driver.enable {
      services.xserver.videoDrivers = [ "nvidia" ];

      hardware.nvidia = {
        package = cfg.driver.package;
        modesetting.enable = cfg.driver.enable;
        nvidiaSettings = cfg.driver.enable;
        open = cfg.driver.enable;
      };
      environment.systemPackages = [
        pkgs.nvidia-vaapi-driver
      ];
    })
  ];
}
