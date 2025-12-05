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
            default = pkgs.cuda.cudaPackages;
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
          pkgs.cuda.nvtopPackages.nvidia
          cfg.cuda.packages.nsight_systems
          nsight_compute
        ];
      })

      (lib.mkIf cfg.driver.enable {
        services.xserver.videoDrivers = [ "nvidia" ];

        hardware.nvidia = {
          # FIXME: This is a workaround for https://github.com/NixOS/nixpkgs/issues/467814
          # FIXME: Remove once the new driver version is released
          package = cfg.driver.package // {
            open = cfg.driver.package.open.overrideAttrs (old: {
              patches = (old.patches or [ ]) ++ [
                (pkgs.fetchpatch {
                  name = "get_dev_pagemap.patch";
                  url = "https://github.com/NVIDIA/open-gpu-kernel-modules/commit/3e230516034d29e84ca023fe95e284af5cd5a065.patch";
                  hash = "sha256-BhL4mtuY5W+eLofwhHVnZnVf0msDj7XBxskZi8e6/k8=";
                })
              ];
            });
          };
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
