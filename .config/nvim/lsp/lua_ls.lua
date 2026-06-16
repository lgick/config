return {
  root_dir = function(fname)
    local root = vim.fs.root(fname, { '.luarc.json', '.luarc.jsonc', '.git' })
    if root == vim.fn.expand('~') then
      return nil
    end
    return root
  end,
}
