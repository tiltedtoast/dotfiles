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
      llvm = pkgs.llvmPackages_21;
    in
    {
      devShells.${system}.default = pkgs.mkShell.override { stdenv = llvm.stdenv; } {
        buildInputs = with pkgs; [
          llvm.openmp
          openmpi
          stdenv.cc.cc.lib
        ];

        packages = with pkgs; [
          llvm.clang-tools
          llvm.lldb
          gnumake
        ];

        CPATH =
          with pkgs;
          lib.makeIncludePath [
            openmpi
            llvm.openmp
          ];

        LD_LIBRARY_PATH =
          pkgs.lib.makeLibraryPath self.devShells.${system}.default.buildInputs;
      };
    };
}
