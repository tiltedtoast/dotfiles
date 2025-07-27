export NIXPKGS_ALLOW_UNFREE=1

#CUDA_ROOT=$(nix --extra-experimental-features 'nix-command flakes' eval --impure --raw github:NixOS/nixpkgs/nixos-unstable#cudaPackages.cudatoolkit)

#export PATH="$CUDA_ROOT/bin:$PATH"

alias nixos-switch="nh os switch"
alias flake-update="sudo nix flake update --flake $NH_FLAKE"

alias update="nh os switch --update"

[ -s "/etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh" ] && . "/etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh"
