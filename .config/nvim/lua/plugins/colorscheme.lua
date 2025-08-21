return {
  "PaperColor",
  lazy = false,
  priority = 1000,
  dir = vim.fn.stdpath("config"),
  config = function()
    vim.cmd.colorscheme("PaperColor")
  end,
}
