local fn = vim.fn
local opt = vim.opt
local api = vim.api
local cmd = vim.cmd

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

  local command = string.format(
    "git -C %s ls-files | grep -E '\\.(js|jsx|ts|tsx)$' | grep -v 'node_modules' | grep -v 'dist'",
    gitPath
  )
  local files = fn.systemlist(command)
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
  cmd('MasonToolsUpdate')
  cmd('TSUpdate')
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

api.nvim_create_user_command('Fold', function()
  -- Проверяем, существует ли переменная vim.b.space
  if fn.exists('b:space') == 0 then
    api.nvim_buf_set_var(0, 'space', 0)
  end

  -- Сворачиваем все блоки
  api.nvim_command('normal zE')

  -- Спрашиваем уровень отступа
  local i = 0
  local lenline = fn.line('$')
  local currentline = fn.line('.')
  cmd('call inputsave()')
  local space =
    fn.input('how many space (current value: ' .. api.nvim_buf_get_var(0, 'space') .. ')? ')
  cmd('call inputrestore()')

  -- Обновляем значение vim.b.space, если пользователь ввел новое значение
  local num_space = tonumber(space)
  if num_space ~= nil then
    api.nvim_buf_set_var(0, 'space', num_space)
  end

  -- значение умножаем на tabstop
  local tabstop = tonumber(vim.opt.tabstop:get()) or 2
  local indent = api.nvim_buf_get_var(0, 'space') * tabstop

  -- Сворачиваем блоки с уровнем отступа, равным vim.b.space
  while i <= lenline do
    local str = fn.getline(i)
    if fn.indent(i) == indent then
      if fn.match(str, '[{(%[]') ~= -1 then
        api.nvim_win_set_cursor(0, { i, 0 })
        api.nvim_command('normal $zf%')
      end
    end
    i = i + 1
  end

  -- Возвращаемся к текущей строке
  api.nvim_win_set_cursor(0, { currentline, 0 })
  api.nvim_command("echo ''")
end, {
  desc = 'Folding',
})
