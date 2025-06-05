{
  lib,
  unstable,
}:
with unstable.cudaPackages;

unstable.pocl.overrideAttrs (old: {
  pname = "pocl-cuda";

  buildInputs = old.buildInputs ++ [
    cudatoolkit
    cuda_cudart
    cuda_nvcc
  ];

  nativeBuildInputs = old.nativeBuildInputs ++ [
    cuda_nvcc
  ];

  cmakeFlags = old.cmakeFlags ++ [
    (lib.cmakeBool "ENABLE_CUDA" true)
    (lib.cmakeFeature "CUDA_TOOLKIT_ROOT_DIR" "${cudatoolkit}")
  ];

  # Disable hardening that's incompatible with NVPTX
  hardeningDisable = [
    "stackprotector"
    "zerocallusedregs"
  ];

  meta = old.meta // {
    description = "POCL with CUDA device backend enabled";
  };
})
