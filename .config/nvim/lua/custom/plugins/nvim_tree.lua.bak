return {
  "nvim-tree/nvim-tree.lua",
  version = "*",
  lazy = false,
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    require("nvim-tree").setup { filters = {
      git_ignored = false,
    },
    }
    vim.keymap.set('n', '<Leader>e', "<cmd>NvimTreeFindFile<cr>", { desc = "Toggle NvimTree" })
  end,
}
