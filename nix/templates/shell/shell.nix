let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz";
  pkgs = import nixpkgs {
    config.allowUnfree = true;
  };
in

pkgs.mkShell {
  buildInputs = with pkgs; [
  ];

  nativeBuildInputs = with pkgs; [
  ];
}
