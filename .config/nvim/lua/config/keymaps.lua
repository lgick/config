local g = vim.g
local cmd = vim.cmd
local api = vim.api
local opt = vim.opt
local notify = vim.notify
local map = vim.keymap.set
local fn = vim.fn

-- <C-o> - переход на предыдущую позицию в списке переходов
-- <C-i> - переход на следующую позицию в списке переходов
-- :ju - лист переходов
-- gc - комментарий в visual mode
-- <C-f> - command history window
-- K - documentation

g.mapleader = ','

------------------------------------------
-- Форматирование текста
------------------------------------------

-- Переключение языка в режиме ввода и поиска
map({ 'c', 'i' }, '<C-l>', '<C-^>', { desc = 'Switching languages' })

-- Сброс языка при выходе из Insert mode
map('i', '<ESC>', '<ESC><cmd>set iminsert=0<CR>', { silent = true, desc = 'Language Reset' })

------------------------------------------
-- Поиск
------------------------------------------

-- Значение поиска по центру экрана
map('n', 'n', 'nzzzv', { desc = 'Search In The Center' })
map('n', 'N', 'Nzzzv', { desc = 'Search In The Center' })

------------------------------------------
-- Hardcore mode
------------------------------------------

-- Отключение стрелочек
map('n', '<Up>', '<nop>', { silent = true })
map('n', '<Down>', '<nop>', { silent = true })
map('n', '<Left>', '<nop>', { silent = true })
map('n', '<Right>', '<nop>', { silent = true })
map('i', '<BS>', '<nop>', { silent = true })
map('c', '<Tab>', '<nop>', { silent = true })

----------------------------------------
-- Hotkeys
----------------------------------------

-- , + p: Открывает предыдущий буфер
map('n', '<leader>p', '<cmd>bp<CR>', { desc = 'Prev Buffer' })

-- , + n: Открывает следующий буфер
map('n', '<leader>n', '<cmd>bn<CR>', { desc = 'Next Buffer' })

-- , + d: Удаляет буфер
map('n', '<leader>d', '<cmd>bdel<CR>', { desc = 'Delete Buffer' })

-- , + c: Копирует в системный буфер
map('v', '<leader>c', '"+y', { desc = 'Copy' })

-- , + v: Вставляет из системного буфера
map('n', '<leader>v', '"+p', { desc = 'Paste' })

-- , + u: Undotree
map('n', '<leader>u', function()
  require('undotree').open({
    title = function(bufnr)
      local file_name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ':t')
      return file_name
    end,
    command = '50vnew',
  })
end, { desc = 'Undotree' })

-- , + f: File Explorer
map('n', '<leader>e', '<cmd>NvimTreeToggle<CR>', { desc = 'Nvim Tree' })

-- , + o: Aerial - code navigation
map('n', '<leader>o', '<cmd>AerialToggle<CR>', { desc = 'Code Navigation' })

--- , + w: Git stage flow
map('n', '<leader>w', '<cmd>GitStageFlow<CR>', { desc = 'Git Stage Flow' })

-- , + y: Autoformat toggle
map('n', '<leader>y', function()
  if g.disable_autoformat then
    g.disable_autoformat = false
    notify('Enabled autoformat')
  else
    g.disable_autoformat = true
    notify('Disabled autoformat')
  end
end, { desc = 'Switching Autoformat' })

-- , + z: Сворачивает функциональные блоки в файле
map('n', '<leader>z', function()
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
end, { desc = 'Folding' })

----------------------------------------
-- Snacks
----------------------------------------

-- поиск файлов
map('n', '<leader>ff', function()
  Snacks.picker.files({ hidden = true })
end, { desc = 'Snacks Find Files' })

-- поиск файлов по всем файлам
map('n', '<leader>fi', function()
  Snacks.picker.files({
    hidden = true,
    ignored = true,
  })
end, { desc = 'Snacks Files (All Files)' })

-- конфиг nvim
map('n', '<leader>fc', function()
  Snacks.picker.files({ cwd = vim.fn.stdpath('config') })
end, { desc = 'Snacks Config Files' })

-- поиск по файлам проекта
map('n', '<leader>g', function()
  Snacks.picker.grep({ hidden = true })
end, { desc = 'Snacks Live Grep' })

-- поиск по всем файлам
map('n', '<leader>G', function()
  Snacks.picker.grep({
    hidden = true,
    ignored = true,
  })
end, { desc = 'Snacks Live Grep (All Files)' })

map('n', '<leader>GW', function()
  Snacks.picker.grep_word({
    hidden = true,
    ignored = true,
  })
end, { desc = 'Snacks Grep Word (All Files)' })

-- буфферы
map('n', '<leader>b', function()
  Snacks.picker.buffers()
end, { desc = 'Snacks Buffers' })

----------------------------------------
-- LSP
----------------------------------------

-- Show LSP references
map('n', '<leader>a', vim.lsp.buf.references, { desc = 'LSP References' })

-- Изменить название в файле (вызвать :wa по завершению)
map('n', '<leader>r', vim.lsp.buf.rename, { desc = 'LSP Rename' })

-- Show LSP definitions
map('n', '<leader>j', vim.lsp.buf.definition, { desc = 'LSP Definition' })

-- See available code actions
map({ 'n', 'v' }, '<leader>m', vim.lsp.buf.code_action, { desc = 'Code Action' })

-- Switching diagnostic
map('n', '<leader>t', function()
  vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end, { desc = 'Switching Diagnostic' })

-- Принудительная загрузка ts-файлов проекта
map('n', '<leader>l', '<cmd>TsLsForceLoad<CR>', { desc = 'TS Force Load' })

----------------------------------------
-- Trouble
----------------------------------------

-- Open trouble document diagnostics
map(
  'n',
  '<leader>x',
  '<cmd>Trouble diagnostics toggle filter.buf=0<CR>',
  { desc = 'Trouble Diagnostics (Buffer)' }
)

-- Open trouble workspace diagnostics
map(
  'n',
  '<leader>X',
  '<cmd>Trouble diagnostics fold_close_all=1<CR>',
  { desc = 'Trouble Diagnostics (All)' }
)

------------------------------------------
-- Codeium
------------------------------------------

-- Открывает чат
map('n', '<leader>h', '<cmd>call codeium#Chat()<CR>', { desc = 'AI' })

------------------------------------------
-- Nvim
------------------------------------------

-- Рестарт nvim
map(
  'n',
  '<leader>1',
  "<cmd>mksession! Session.vim | restart source Session.vim | call delete('Session.vim')<CR>",
  { desc = 'Restart Nvim' }
)

-- Определяет синтаксис слова под курсором
map('n', '<leader>2', '<cmd>Inspect<CR>', { desc = 'Inspect Nvim' })

-- Группы подсветки
map('n', '<leader>3', function()
  Snacks.picker.highlights({ pattern = 'hl_group:' })
end, { desc = 'Snacks Highlights' })

-- Keymaps
map('n', '<leader>4', function()
  Snacks.picker.keymaps()
end, { desc = 'Snacks Keymaps' })

-- Отображает сообщения в новом буфере
map('n', '<leader>5', "<cmd>new | put =execute('messages')<CR>", { desc = 'Messages Nvim' })

-- Проверяет работу плагинов nvim
map('n', '<leader>7', '<cmd>checkhealth<CR>', { desc = 'Checkhealth Nvim' })

-- Обновляет плагины nvim
map('n', '<leader>8', function()
  local confirm = fn.input('Обновить плагины Neovim? (y/n): ')

  if confirm:lower() ~= 'y' then
    return
  end

  vim.pack.update()
  vim.cmd('MasonToolsUpdate')
  vim.cmd('TSUpdate')
end, { desc = 'Update Nvim Plugins' })

-- Сбрасывает nvim до заводских настроек
map('n', '<leader>9', function()
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
end, { desc = 'Reset Nvim' })
