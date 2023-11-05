return {
  "ThePrimeagen/refactoring.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  config = function()
    require("refactoring").setup {}

    vim.keymap.set("x", "<leader>re", ":Refactor extract ", { desc = '[r]efactor [e]xtract' })
    vim.keymap.set("x", "<leader>rf", ":Refactor extract_to_file ", { desc = '[r]efactor extract to [f]ile' })
    vim.keymap.set("x", "<leader>rv", ":Refactor extract_var ", { desc = '[r]efactor extract [v]ar' })
    vim.keymap.set({ "n", "x" }, "<leader>ri", ":Refactor inline_var", { desc = '[r]efactor [i]nline var' })
    vim.keymap.set("n", "<leader>rI", ":Refactor inline_func", { desc = '[r]efactor [I]nline func' })
    vim.keymap.set("n", "<leader>rb", ":Refactor extract_block", { desc = '[r]efactor extract [b]lock' })
    vim.keymap.set("n", "<leader>rbf", ":Refactor extract_block_to_file", { desc = '[r]efactor extract [b]lock to [f]ile' })

    vim.keymap.set(
      "n",
      "<leader>rp",
      function() require('refactoring').debug.printf({ below = false }) end, { desc = '[r]efactor [p]rint execution' }
    )
    vim.keymap.set({ "x", "n" }, "<leader>rv", function() require('refactoring').debug.print_var({}) end,
      { desc = '[r]efactor print [v]ar' })
    vim.keymap.set("n", "<leader>rc", function() require('refactoring').debug.cleanup({}) end,
      { desc = '[r]efactor [c]leanup print statements' })
  end,
}
