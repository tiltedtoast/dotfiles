{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    { nixpkgs, self }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        system = system;
        config.allowUnfree = true;
      };
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs.cudaPackages; [
          cudatoolkit
          cuda_nvcc
          cuda_cudart
          cuda_gdb
          pkgs.stdenv.cc.cc.lib
        ];

        LD_LIBRARY_PATH =
          pkgs.lib.makeLibraryPath self.devShells.${system}.default.buildInputs + ":/run/opengl-driver/lib";
      };
    };
}
