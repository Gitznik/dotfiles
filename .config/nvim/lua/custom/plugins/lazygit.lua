return {
  "kdheepak/lazygit.nvim",
  version = "*",
  lazy = false,
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  config = function()
    require("lazy").setup {}
  end,
}
