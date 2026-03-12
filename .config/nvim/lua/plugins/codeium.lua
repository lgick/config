return {
  "Exafunction/codeium.vim",
  event = "BufEnter",
  config = function()
    local g = vim.g

    g.codeium_disable_bindings = 1
    g.codeium_render = false
  end,
}
