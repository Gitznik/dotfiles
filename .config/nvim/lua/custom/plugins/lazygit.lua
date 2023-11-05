return {
  "kdheepak/lazygit.nvim",
  version = "*",
  lazy = false,
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  config = function()
    require("lazy").setup {}
    vim.keymap.set('n', '<Leader>gg', require('lazygit').lazygit, { desc = 'Toggle LazyGit' })
  end,
}
