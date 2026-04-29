local g = vim.g
local opt = vim.opt
local notify = vim.notify
local map = vim.keymap.set

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
map('n', '<leader>d', '<cmd>Bufdelete<CR>', { desc = 'Delete Buffer And Switch' })

-- , + c: Копирует в системный буфер
map('v', '<leader>c', '"+y', { desc = 'Copy' })

-- , + v: Вставляет из системного буфера
map('n', '<leader>v', '"+p', { desc = 'Paste' })

-- , + f: File Explorer
map('n', '<leader>f', '<cmd>NvimTreeToggle<CR>', { desc = 'Nvim Tree' })

-- , + o: Aerial - code navigation
map('n', '<leader>o', '<cmd>AerialToggle<CR>', { desc = 'Code Navigation' })

-- , + i: Открывает чат
map('n', '<leader>i', '<cmd>call codeium#Chat()<CR>', { desc = 'AI' })

-- , + z: Сворачивает функциональные блоки в файле
map('n', '<leader>z', '<cmd>Fold<CR>', { desc = 'Folding' })

----------------------------------------
-- Utility
----------------------------------------

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
-- Git
----------------------------------------

-- , + gs: Git stage
map('n', '<leader>gs', '<cmd>GitStageFlow<CR>', { desc = 'Git Stage Flow' })

-- , + gh: Git history
map({ 'n', 'x' }, '<leader>gh', function()
  local mode = vim.fn.mode()

  if mode == 'v' or mode == 'V' or mode == '\22' then
    -- Поведение Visual mode
    vim.cmd('normal! \27')
    vim.cmd("'<,'>DiffviewFileHistory")
  else
    -- Поведение Normal mode
    vim.cmd('DiffviewFileHistory %')
  end
end, { desc = 'Git File History' })

-- , + gd: Git diff
map('n', '<leader>gd', '<cmd>DiffviewOpen<CR>', { desc = 'Git Diff Open' })

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
map('n', '<leader>6', '<cmd>checkhealth<CR>', { desc = 'Checkhealth Nvim' })

-- Принудительная загрузка ts-файлов проекта
map('n', '<leader>7', '<cmd>TsLsForceLoad<CR>', { desc = 'TS Force Load' })

-- Обновляет плагины nvim
map('n', '<leader>8', '<cmd>UpdateNvimPlugins<CR>', { desc = 'Update Nvim Plugins' })

-- Сбрасывает nvim до заводских настроек
map('n', '<leader>9', '<cmd>ResetNvim<CR>', { desc = 'Reset Nvim' })
