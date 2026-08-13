-- lazydev.nvim переопределяет root_dir через явный vim.lsp.config('lua_ls', ...)
-- (lua/lazydev/integrations/lspconfig.lua) — такой вызов имеет более высокий
-- приоритет слияния, чем таблица, возвращаемая этим файлом, поэтому наш
-- root_dir ниже фактически никогда не используется. Когда lazydev не может
-- определить workspace для буфера (например виртуальный буфер diffview без
-- реального пути на диске), он всё равно вызывает on_dir(nil), и
-- vim.lsp.start() откатывается на root_markers. Дефолтный root_markers из
-- nvim-lspconfig включает '.git', а $HOME сам является git-репозиторием —
-- сервер получает workspace = $HOME и отказывается его грузить.
--
-- Поэтому root_markers переопределяем тем же способом (явный вызов, тот же
-- приоритетный слой, что и у lazydev), исключая '.git', и требуем
-- workspace_required, чтобы при нерезолвленном root сервер просто не
-- подключался к буферу, а не отваливался с ошибкой.
vim.lsp.config('lua_ls', {
  root_markers = { '.luarc.json', '.luarc.jsonc' },
  workspace_required = true,
})

return {
  root_dir = function(bufnr, on_dir)
    on_dir(vim.fs.root(bufnr, { '.luarc.json', '.luarc.jsonc' }))
  end,
}
