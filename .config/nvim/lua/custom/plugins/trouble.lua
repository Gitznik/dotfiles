return {
 "folke/trouble.nvim",
 dependencies = { "nvim-tree/nvim-web-devicons" },
 opts = {
  -- your configuration comes here
  -- or leave it empty to use the default settings
  -- refer to the configuration section below
 },
  vim.keymap.set("n", "<leader>tx", function() require("trouble").toggle() end, { desc = "Toggle Trouble"} ),
  vim.keymap.set("n", "<leader>tw", function() require("trouble").toggle("workspace_diagnostics") end, { desc = "Toggle Trouble Workspace Diagnostics"} ),
  vim.keymap.set("n", "<leader>td", function() require("trouble").toggle("document_diagnostics") end, { desc = "Toggle Trouble Document Diagnostics"} ),
  vim.keymap.set("n", "<leader>tq", function() require("trouble").toggle("quickfix") end, { desc = "Toggle Trouble Quickfix"} ),
  vim.keymap.set("n", "<leader>tl", function() require("trouble").toggle("loclist") end, { desc = "Toggle Trouble Location List"} ),
  vim.keymap.set("n", "gR", function() require("trouble").toggle("lsp_references") end, { desc = "Toggle Trouble LSP References"} ),
}
