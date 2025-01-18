return {
  {
    "FabijanZulj/blame.nvim",
    lazy = false,
    config = function()
      require("blame").setup({
        mappings = {
          commit_info = "i",
          stack_push = "<C-j>",
          stack_pop = "<C-k>",
          show_commit = "<CR>",
          close = { "<esc>", "q" },
        },
      })
    end,
    opts = {},
  },
}
