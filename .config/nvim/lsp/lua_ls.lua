-- ============================================================================
-- root_dir
-- ============================================================================
-- $HOME является git-репозиторием (в нём лежат дотфайлы, включая ~/.config/nvim).
-- Поэтому root_dir здесь переопределён вручную вместо root_markers:
--   1. Если буфер — файл конфига Neovim (~/.config/nvim/...), root всегда
--      = stdpath('config'), без поиска маркеров вообще. Это отдельный
--      workspace по определению, и его не нужно искать через .git/.luarc.json
--   2. Иначе — обычный поиск как у lua-language-server/nvim-lspconfig по
--      умолчанию: .luarc.json/.emmyrc.json → конфиги форматтеров/линтеров →
--      .git.
--   3. НО если результат шага 2 оказался ровно $HOME — отклоняем его
--      (on_dir не вызывается). Для остальных git-репозиториев
--      '.git' по-прежнему работает нормально, т.к. их
--      корень — не $HOME.
--
-- root_markers ниже — это fallback внутри vim.lsp.start(), если root_dir
-- вернёт nil: специально сужен до .luarc.json/.luarc.jsonc (без '.git'),
-- чтобы даже в этом fallback-сценарии не откатиться на $HOME.
--
-- workspace_required = true — если root так и не резолвился, сервер просто не
-- подключается к буферу, а не падает с ошибкой.
local home = vim.uv.os_homedir()
local config_dir = vim.fs.normalize(vim.fn.stdpath('config'))

return {
  root_dir = function(bufnr, on_dir)
    local fname = vim.fs.normalize(vim.api.nvim_buf_get_name(bufnr))

    if fname:sub(1, #config_dir + 1) == config_dir .. '/' then
      on_dir(config_dir)
      return
    end

    local root = vim.fs.root(bufnr, { '.emmyrc.json', '.luarc.json', '.luarc.jsonc' })
      or vim.fs.root(
        bufnr,
        { '.luacheckrc', '.stylua.toml', 'stylua.toml', 'selene.toml', 'selene.yml' }
      )
      or vim.fs.root(bufnr, { '.git' })

    if root and root ~= home then
      on_dir(root)
    end
  end,
  root_markers = { '.luarc.json', '.luarc.jsonc' },
  workspace_required = true,

  -- ==========================================================================
  -- settings.Lua — базовые настройки для ВСЕХ Lua-проектов
  -- ==========================================================================

  settings = {
    Lua = {
      runtime = { version = 'LuaJIT' },
      diagnostics = { globals = { 'vim' } },
    },
  },

  -- ==========================================================================
  -- on_init — доп. настройки ТОЛЬКО для workspace = конфиг Neovim
  -- ==========================================================================

  on_init = function(client)
    if client.root_dir ~= config_dir then
      return
    end

    client.settings = vim.tbl_deep_extend('force', client.settings or {}, {
      Lua = {
        diagnostics = {
          globals = { 'vim', 'Snacks' },
          disable = { 'undefined-field' },
        },
      },
    })
    client:notify('workspace/didChangeConfiguration', { settings = client.settings })
  end,
}
