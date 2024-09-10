local g = vim.g

g.codeium_disable_bindings = 1
g.codeium_render = false

return {
  "Exafunction/codeium.vim",
  event = "BufEnter",
}
