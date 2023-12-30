return {
  'echasnovski/mini.nvim',
  version = "*",
  config = function()
    -- require("mini.animate").setup {}
    require("mini.surround").setup {}
    -- require("mini.completion").setup {}
    require("mini.files").setup {}
    local function open_explorer()
      require("mini.files").open(vim.api.nvim_buf_get_name(0))
    end
    vim.keymap.set('n', '<Leader>e', open_explorer, { desc = "Open file explorer" })
  end,
}
