{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    {
      packages.${builtins.currentSystem}.default = nixpkgs.lib.callPackage ./default.nix { };
    };
}
