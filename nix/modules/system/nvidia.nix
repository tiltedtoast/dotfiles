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

  config =
    let
      pocl-cuda = pkgs.callPackage ../../overlays/pocl-cuda.nix {
        cudaPkgs = cfg.cuda.packages;
      };
      nsight_compute = pkgs.callPackage ../../overlays/nsight_compute.nix {
        cudaPkgs = cfg.cuda.packages;
      };
      nsight_systems = pkgs.callPackage ../../overlays/nsight_systems.nix {
        cudaPkgs = cfg.cuda.packages;
      };
    in
    lib.mkMerge [
      (lib.mkIf (cfg.cuda.enable || cfg.driver.enable) {
        hardware.graphics = {
          enable = true;
        };
      })

      (lib.mkIf (cfg.cuda.enable && cfg.driver.enable) {
        # https://developer.nvidia.com/nvidia-development-tools-solutions-err_nvgpuctrperm-permission-issue-performance-counters
        boot.kernelParams = [
          "nvidia.NVreg_RestrictProfilingToAdminUsers=0"
        ];
      })

      (lib.mkIf (cfg.cuda.enable && !cfg.driver.enable) {
        hardware.graphics.extraPackages = [
          pocl-cuda
        ];

        environment.variables = {
          OCL_ICD_FILENAMES = "${pocl-cuda}/etc/OpenCL/vendors/pocl.icd";
        };
      })

      # CUDA configuration
      (lib.mkIf cfg.cuda.enable {

        environment.variables.CUDA_PATH = "${cfg.cuda.packages.cudatoolkit}";

        environment.systemPackages = [
          cfg.cuda.packages.cudatoolkit
          pkgs.nvtopPackages.nvidia
          nsight_systems
          nsight_compute
        ];
      })

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
