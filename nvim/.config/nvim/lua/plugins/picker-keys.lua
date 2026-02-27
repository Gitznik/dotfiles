return {
  "folke/snacks.nvim",
  keys = {
    { "<leader>/",       LazyVim.pick("grep", { root = false }),      desc = "Grep (cwd)" },
    { "<leader><space>", LazyVim.pick("files", { root = false }),     desc = "Find Files (cwd)" },
    { "<leader>ff",      LazyVim.pick("files", { root = false }),     desc = "Find Files (cwd)" },
    { "<leader>fF",      LazyVim.pick("files"),                       desc = "Find Files (Root Dir)" },
    { "<leader>sg",      LazyVim.pick("live_grep", { root = false }), desc = "Grep (cwd)" },
    { "<leader>sG",      LazyVim.pick("live_grep"),                   desc = "Grep (Root Dir)" },
  },
}
