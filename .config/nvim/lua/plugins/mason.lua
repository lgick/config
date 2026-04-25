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

local function force_load_ts_ls()
  local clients = vim.lsp.get_clients({ name = 'ts_ls' })
  if #clients == 0 then
    print('❌ Ошибка: ts_ls не запущен в данном буфере!')
    return
  end

  local client = clients[1]
  print('⏳ Начинаю загрузку файлов проекта в ts_ls...')

  local gitPath = vim.fn.systemlist('git rev-parse --show-toplevel')[1]
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
  local files = vim.fn.systemlist(cmd)
  local count = 0

  for _, file in ipairs(files) do
    local abs_path = gitPath .. '/' .. file

    if vim.fn.filereadable(abs_path) == 1 then
      local uri = vim.uri_from_fname(abs_path)
      local lines = vim.fn.readfile(abs_path)
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
end

-- Создаем команду, которую будет видно во всем Neovim
vim.api.nvim_create_user_command('TsLsForceLoad', force_load_ts_ls, {
  desc = 'Принудительно загрузить все файлы проекта в ts_ls',
})
