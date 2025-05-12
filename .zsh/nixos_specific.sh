export NIXPKGS_ALLOW_UNFREE=1

CUDA_ROOT=$(nix --extra-experimental-features nix-command --extra-experimental-features flakes eval --impure --raw nixpkgs#cudaPackages.cudatoolkit)

export PATH="$CUDA_ROOT/bin:$PATH"

alias nixos-switch="sudo nixos-rebuild switch --flake $HOME/dotfiles/nix"