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
    cudaPkgs = pkgs.cudaPackages_12_9;
    llvm = pkgs.llvmPackages_20;
    in
    {
      devShells.${system}.default = pkgs.mkShell.override { stdenv = llvm.stdenv; } {
        buildInputs = with cudaPkgs; [
          cudatoolkit
          cuda_cudart
          pkgs.stdenv.cc.cc.lib
        ];

        packages = with pkgs; [
          llvm.clang-tools
          llvm.lldb
          gnumake
        ];

        CPATH = pkgs.lib.makeIncludePath [
          cudaPkgs.cudatoolkit
        ];

        LD_LIBRARY_PATH =
          pkgs.lib.makeLibraryPath self.devShells.${system}.default.buildInputs + ":/run/opengl-driver/lib";
      };
    };
}
