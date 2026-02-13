return {
  "neovim/nvim-lspconfig",
  opts = {
    inlay_hints = { enabled = false },
    servers = {
      templ = {
        filetypes = { "templ" },
        settings = {
          templ = {
            enable_snippets = true,
          },
        },
      },
      gopls = {
        settings = {
          gopls = {
            analyses = {
              ST1000 = false,
            },
          },
        },
      },
      buf_ls = {},
    },
  }
}
