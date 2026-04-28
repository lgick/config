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
-- K - documentation (vim.lsp.buf.hover())

-- "gra" (Normal and Visual mode) is mapped to |vim.lsp.buf.code_action()|
-- "gri" is mapped to |vim.lsp.buf.implementation()|
-- "grn" is mapped to |vim.lsp.buf.rename()|
-- "grr" is mapped to |vim.lsp.buf.references()|
-- "grt" is mapped to |vim.lsp.buf.type_definition()|
-- "grx" is mapped to |vim.lsp.codelens.run()|
-- "gO" is mapped to |vim.lsp.buf.document_symbol()|
-- CTRL-S (Insert mode) is mapped to |vim.lsp.buf.signature_help()|

g.mapleader = ','

------------------------------------------
-- Форматирование текста
------------------------------------------

-- Переключение языка в режиме ввода и поиска
map({ 'c', 'i' }, '<C-l>', '<C-^>', { desc = 'Toggle language' })

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

-- , + e: File Explorer
map('n', '<leader>e', '<cmd>NvimTreeToggle<CR>', { desc = 'Nvim Tree' })

-- , + o: Aerial - code navigation
map('n', '<leader>o', '<cmd>AerialToggle<CR>', { desc = 'Code Navigation' })

-- , + g: Git stage flow
map('n', '<leader>g', '<cmd>GitStageFlow<CR>', { desc = 'Git Stage Flow' })

-- , + l: Принудительная загрузка ts-файлов проекта
map('n', '<leader>l', '<cmd>TsLsForceLoad<CR>', { desc = 'TS Force Load' })

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
-- Utility
----------------------------------------

-- , + uc: Подсвечивает координаты курсора
map('n', '<leader>uc', function()
  local is_on = vim.opt.cursorline:get()

  vim.opt.cursorline = not is_on
  vim.opt.cursorcolumn = not is_on
  notify(not is_on and 'Crosshair On' or 'Crosshair Off')
end, { desc = 'Toggle Cursor Crosshair' })

-- , + uf: Autoformat toggle
map('n', '<leader>uf', function()
  if g.disable_autoformat then
    g.disable_autoformat = false
    notify('Enabled autoformat')
  else
    g.disable_autoformat = true
    notify('Disabled autoformat')
  end
end, { desc = 'Toggle Autoformat' })

-- , + ud: Toggle diagnostic
map('n', '<leader>ud', function()
  local is_enabled = not vim.diagnostic.is_enabled()

  vim.diagnostic.enable(is_enabled)
  notify(is_enabled and 'Diagnostics On' or 'Diagnostics Off')
end, { desc = 'Toggle Diagnostic' })

----------------------------------------
-- Snacks
----------------------------------------

-- поиск файлов
map('n', '<leader>sff', function()
  Snacks.picker.files({ hidden = true })
end, { desc = 'Find Files' })

-- поиск файлов везде
map('n', '<leader>sfi', function()
  Snacks.picker.files({
    hidden = true,
    ignored = true,
  })
end, { desc = 'Find Files (All)' })

-- буфферы
map('n', '<leader>sfb', function()
  Snacks.picker.buffers()
end, { desc = 'Buffer Files' })

-- недавно открытые файлы
map('n', '<leader>sfr', function()
  Snacks.picker.recent({ filter = { cwd = true } })
end, { desc = 'Recent Files' })

-- конфиг nvim
map('n', '<leader>sfc', function()
  Snacks.picker.files({ cwd = vim.fn.stdpath('config') })
end, { desc = 'Config Files' })

-- поиск в файлах
map('n', '<leader>sgg', function()
  Snacks.picker.grep({ hidden = true })
end, { desc = 'Live Grep' })

-- поиск во всех файлах
map('n', '<leader>sgi', function()
  Snacks.picker.grep({
    hidden = true,
    ignored = true,
  })
end, { desc = 'Live Grep (All Files)' })

-- поиск конкретного слова в файлах
map({ 'n', 'v' }, '<leader>sgw', function()
  Snacks.picker.grep_word({
    hidden = true,
    ignored = true,
  })
end, { desc = 'Live Grep Word (All Files)' })

----------------------------------------
-- Trouble
----------------------------------------

map(
  'n',
  '<leader>x',
  '<cmd>Trouble diagnostics toggle filter.buf=0<CR>',
  { desc = 'Trouble Diagnostics (Buffer)' }
)

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
-- System
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
