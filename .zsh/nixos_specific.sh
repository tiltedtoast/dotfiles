export NIXPKGS_ALLOW_UNFREE=1

CUDA_ROOT=$(nix --extra-experimental-features 'nix-command flakes' eval --impure --raw github:NixOS/nixpkgs/nixos-unstable#cudaPackages.cudatoolkit)

export PATH="$CUDA_ROOT/bin:$PATH"

alias nixos-switch="sudo nixos-rebuild switch --flake $HOME/dotfiles/nix-config"
alias flake-update="sudo nix flake update --flake $HOME/dotfiles/nix-config"