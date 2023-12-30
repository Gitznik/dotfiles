return {
  "folke/todo-comments.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  opts = {},
  vim.keymap.set('n', '<Leader>tt', "<cmd>TodoTelescope<cr>", { desc = "Find open TODO: blocks" })
}
