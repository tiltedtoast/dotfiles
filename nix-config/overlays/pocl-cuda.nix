self: super:
let
  cuda = super.cudaPackages;
in
{
  pocl-cuda = super.pocl.overrideAttrs (oldAttrs: {
    pname = "pocl-cuda";

    buildInputs = oldAttrs.buildInputs ++ [
      cuda.cudatoolkit
      cuda.cuda_cudart
      cuda.cuda_nvcc
    ];

    nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [
      cuda.cuda_nvcc
    ];

    cmakeFlags = oldAttrs.cmakeFlags ++ [
      (super.lib.cmakeBool "ENABLE_CUDA" true)
      (super.lib.cmakeFeature "CUDA_TOOLKIT_ROOT_DIR" "${cuda.cudatoolkit}")
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
