{
  cudaPkgs,
}:

self: super:

{
  pocl-cuda = super.pocl.overrideAttrs (oldAttrs: {
    pname = "pocl-cuda";
    buildInputs = oldAttrs.buildInputs ++ [
      cudaPkgs.cudatoolkit
      cudaPkgs.cuda_cudart
      cudaPkgs.cuda_nvcc
    ];
    nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [
      cudaPkgs.cuda_nvcc
    ];
    cmakeFlags = oldAttrs.cmakeFlags ++ [
      (super.lib.cmakeBool "ENABLE_CUDA" true)
      (super.lib.cmakeFeature "CUDA_TOOLKIT_ROOT_DIR" "${cudaPkgs.cudatoolkit}")
    ];
    hardeningDisable = oldAttrs.hardeningDisable or [ ] ++ [
      "stackprotector"
      "zerocallusedregs"
    ];
    meta = oldAttrs.meta // {
      description = "POCL with CUDA device backend enabled";
    };
  });
}
