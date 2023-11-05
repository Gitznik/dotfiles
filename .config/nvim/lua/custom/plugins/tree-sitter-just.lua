return {
  "IndianBoy42/tree-sitter-just",
  version = "*",
  lazy = false,
  config = function()
    require"nvim-treesitter.install".compilers = {"gcc-11"}
    require("tree-sitter-just").setup {}
  end,
}
