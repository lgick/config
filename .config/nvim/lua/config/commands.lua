local utils = require('utils')
local fn = vim.fn
local opt = vim.opt
local api = vim.api
local cmd = vim.cmd
local wo = vim.wo

api.nvim_create_user_command('UpdateInsertModeColor', function()
  local win = api.nvim_get_current_win()
  local current = wo[win].winhighlight
  local mode = api.nvim_get_mode().mode
  local is_insert = mode:sub(1, 1) == 'i'
  local new_parts = {}

  -- Очищаем все старые упоминания
  if current ~= '' then
    for _, part in ipairs(vim.split(current, ',')) do
      if
        part ~= ''
        and not part:match('^StatusLine:StatusLineInsert')
        and not part:match('^CursorLineNr:CursorLineNrInsert')
      then
        table.insert(new_parts, part)
      end
    end
  end

  if is_insert then
    local lang = opt.iminsert:get()

    if lang == 0 then
      table.insert(new_parts, 'CursorLineNr:CursorLineNrInsertEn')
    elseif lang == 1 then
      table.insert(new_parts, 'CursorLineNr:CursorLineNrInsertRu')
    end

    table.insert(new_parts, 'StatusLine:StatusLineInsert')
  end

  vim.wo.winhighlight = table.concat(new_parts, ',')
end, {
  desc = 'Обновляет цвета в Insert mode',
})

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

utils.create_confirm_command({
  name = 'UpdateNvimPlugins',
  prompt = 'Обновить плагины Neovim? (y/n): ',
  desc = 'Update Nvim Plugins',
  action = function()
    vim.pack.update()
    cmd('MasonToolsUpdate')
    cmd('TSUpdate')
  end,
})

utils.create_confirm_command({
  name = 'ResetNvim',
  prompt = 'ПОЛНОСТЬЮ сбросить Neovim? (y/n): ',
  desc = 'Reset Nvim',
  action = function()
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
  end,
})

api.nvim_create_user_command('Fold', function()
  vim.b.space = vim.b.space or 0

  local prompt_str = string.format('how many space (current value: %d)? ', vim.b.space)

  vim.ui.input({ prompt = prompt_str }, function(input)
    cmd('redraw!')
    api.nvim_echo({}, false, {})

    -- Если отмена ввода (Esc)
    if input == nil then
      return
    end

    local num_space = tonumber(input)
    -- Если ввели число, обновление значения
    -- Если пустой Enter ("") или буквы ("abc"),
    -- num_space будет nil, значение не обновляется.
    if num_space ~= nil then
      vim.b.space = num_space
    end

    cmd('normal! zE')

    local lenline = fn.line('$')
    local currentline = fn.line('.')
    local tabstop = tonumber(vim.opt.tabstop:get()) or 2
    local indent = vim.b.space * tabstop

    local i = 0

    while i <= lenline do
      local str = fn.getline(i)
      if fn.indent(i) == indent then
        if fn.match(str, '[{(%[]') ~= -1 then
          api.nvim_win_set_cursor(0, { i, 0 })
          cmd('normal! $zf%')
        end
      end
      i = i + 1
    end

    -- Возврат к текущей строке
    api.nvim_win_set_cursor(0, { currentline, 0 })
  end)
end, {
  desc = 'Folding',
})

api.nvim_create_user_command('Bufdelete', function()
  local curr_buf = vim.api.nvim_get_current_buf()
  local bufs = vim.fn.getbufinfo({ buflisted = 1 })

  if #bufs <= 1 then
    -- Если это последний буфер, создать новый пустой и удалить текущий
    cmd('enew')
    api.nvim_buf_delete(curr_buf, { force = false })
  else
    -- Если буферов много, переход на следующий и удалить текущий
    cmd('bn')
    api.nvim_buf_delete(curr_buf, { force = false })
  end
end, {
  desc = 'Delete Buffer And Switch',
})
