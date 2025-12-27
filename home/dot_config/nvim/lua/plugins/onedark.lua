return {
  {
    "olimorris/onedarkpro.nvim",
    priority = 1000, -- Ensure it loads first

    config = function()
      require("onedarkpro").setup({
        colors = {
          onedark_dark = { bg = "#111111" },
        }
      })
    end
  }
}
