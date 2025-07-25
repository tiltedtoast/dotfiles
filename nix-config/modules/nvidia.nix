{
  pkgs,
  ...
}:

{

  nixpkgs.overlays = [
    (import ../overlays/pocl-cuda.nix)
  ];

  hardware.graphics.extraPackages = [
    pkgs.pocl-cuda
  ];

  environment.variables = {
    OCL_ICD_FILENAMES = "${pkgs.pocl-cuda}/etc/OpenCL/vendors/pocl.icd";
    CUDA_PATH = "${pkgs.cudatoolkit}";
    CUDA_ROOT = "${pkgs.cudatoolkit}";

    CPATH = [
      "${pkgs.cudatoolkit}/include"
    ];

    LD_LIBRARY_PATH = [
      "${pkgs.cudatoolkit}/lib"
      "${pkgs.cudaPackages.cuda_cudart.static}/lib"
    ];
  };

  environment.shellAliases = {
    # Thanks for trying to access /run/current-system/sw/bin/../nvvm/bin/cicc
    nvcc = "${pkgs.cudaPackages.cudatoolkit}/bin/nvcc";
  };

  environment.systemPackages = with pkgs.cudaPackages; [
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
  ];
}
