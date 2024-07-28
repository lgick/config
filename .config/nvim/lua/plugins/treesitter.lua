require'nvim-treesitter.configs'.setup {
  ensure_installed = {"typescript", "lua", "tsx", "typescript", "javascript", "html", "css"},
  sync_install = false,
  auto_install = true,
  highlight = {
    enable = true
  }
}

