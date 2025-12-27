return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        clangd = {
          mason = false,

          cmd = {
            "clangd",
            "--function-arg-placeholders=0",
            "--background-index",
            "--all-scopes-completion",
            "--clang-tidy",
            "--malloc-trim",
            "--header-insertion-decorators=0"
          },
        },
      },
    },
  },
}
