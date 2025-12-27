return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        nixd = {
          cmd = { "nixd" },
          settings = {
            nixd = {
              nixpkgs = {
                expr = "import (builtins.getFlake(toString ./.)).inputs.nixpkgs",
              },
              formatting = {
                command = { "nixfmt" },
              },
              options = {
                nixos = {
                  expr = '(builtins.getFlake "/home/tim/dotfiles/nix").nixosConfigurations.nixos-pc.options',
                },
                ["home-manager"] = {
                  expr =
                  '(builtins.getFlake "/home/tim/dotfiles/nix").nixosConfigurations.nixos-pc.options.home-manager.users.type.getSubOptions []',
                },
              },
            },
          },
        },
      },
    },
  },
}
