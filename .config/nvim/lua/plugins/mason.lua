require('mason').setup()
require('mason-lspconfig').setup()
require('mason-tool-installer').setup({
  ensure_installed = {
    'ts_ls',
    'html',
    'cssls',
    'stylua',
    'prettierd',
    'eslint-lsp',
    'lua_ls',
    'tailwindcss-language-server',
    'graphql',
    'nginx_language_server',
    'nginx-config-formatter',
    'tree-sitter-cli',
    'json-lsp',
  },
  auto_update = true,
  run_on_start = true,
})

vim.diagnostic.config({
  virtual_text = false, -- Отображает текст ошибок в строке
  signs = false, -- Оставляет значки слева в statuscolumn
  underline = true, -- Оставляет подчеркивание под проблемным кодом
  update_in_insert = false, -- Обновляет ошибки во время ввода
  severity_sort = true, -- Приоритет более важных ошибок
})

local fn = vim.fn
local opt = vim.opt
local api = vim.api

api.nvim_create_user_command('TsLsForceLoad', function()
  local clients = vim.lsp.get_clients({ name = 'ts_ls' })

  if #clients == 0 then
    print('❌ Ошибка: ts_ls не запущен в данном буфере!')
    return
  end

  local client = clients[1]
  print('⏳ Начинаю загрузку файлов проекта в ts_ls...')

  local gitPath = fn.systemlist('git rev-parse --show-toplevel')[1]

  if not gitPath or gitPath == '' or gitPath:match('fatal') then
    print(
      '❌ Ошибка: Не удалось найти корень git-репозитория'
    )
    return
  end

  local cmd = string.format(
    "git -C %s ls-files | grep -E '\\.(js|jsx|ts|tsx)$' | grep -v 'node_modules' | grep -v 'dist'",
    gitPath
  )
  local files = fn.systemlist(cmd)
  local count = 0

  for _, file in ipairs(files) do
    local abs_path = gitPath .. '/' .. file

    if fn.filereadable(abs_path) == 1 then
      local uri = vim.uri_from_fname(abs_path)
      local lines = fn.readfile(abs_path)
      local text = table.concat(lines, '\n')
      local langId = 'javascript'

      if file:match('%.ts$') then
        langId = 'typescript'
      elseif file:match('%.tsx$') then
        langId = 'typescriptreact'
      elseif file:match('%.jsx$') then
        langId = 'javascriptreact'
      end

      client.rpc.notify('textDocument/didOpen', {
        textDocument = { uri = uri, languageId = langId, version = 0, text = text },
      })

      count = count + 1
    end
  end

  print(
    '✅ УСПЕХ: В ts_ls принудительно загружено '
      .. count
      .. ' файлов!'
  )
end, {
  desc = 'Принудительно загрузить все файлы проекта в ts_ls',
})

api.nvim_create_user_command('UpdateNvimPlugins', function()
  local confirm = fn.input('Обновить плагины Neovim? (y/n): ')

  if confirm:lower() ~= 'y' then
    return
  end

  vim.pack.update()
  vim.cmd('MasonToolsUpdate')
  vim.cmd('TSUpdate')
end, {
  desc = 'Update Nvim Plugins',
})

api.nvim_create_user_command('ResetNvim', function()
  local confirm = fn.input('ПОЛНОСТЬЮ сбросить Neovim? (y/n): ')

  if confirm:lower() ~= 'y' then
    return
  end

  local paths = {
    fn.stdpath('cache'), -- ~/.cache/nvim
    fn.stdpath('data'), -- ~/.local/share/nvim
    fn.stdpath('state'), -- ~/.local/state/nvim
    fn.stdpath('config') .. '/nvim-pack-lock.json',
  }

  for _, path in ipairs(paths) do
    if fn.empty(fn.glob(path)) == 0 then
      fn.delete(path, 'rf')
    end
  end

  opt.shada = ''
  os.exit()
end, {
  desc = 'Reset Nvim',
})
