return {
  root_dir = function(fname)
    return vim.fs.root(fname, { '.luarc.json', '.luarc.jsonc' })
  end,
}
