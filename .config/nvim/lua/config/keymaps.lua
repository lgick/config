local g = vim.g
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

-- Выход из терминала в Normal mode по <Esc>
map('t', '<ESC>', [[<C-\><C-n>]], { desc = 'Exit terminal mode' })

------------------------------------------
-- Форматирование текста
------------------------------------------

-- Переключение языка в режиме ввода и поиска
map({ 'c', 'i' }, '<C-l>', function()
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-^>', true, false, true), 'n', false)

  vim.schedule(function()
    vim.cmd('UpdateInsertModeColor')
  end)
end, {
  desc = 'Toggle language',
})

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
map('x', '<leader>c', '"+y', { desc = 'Copy' })

-- , + v: Вставляет из системного буфера
map('n', '<leader>v', '"+p', { desc = 'Paste' })

-- , + f: File Explorer
map('n', '<leader>f', '<cmd>NvimTreeToggle<CR>', { desc = 'Nvim Tree' })

-- , + o: Aerial - code navigation
map('n', '<leader>o', '<cmd>AerialToggle<CR>', { desc = 'Code Navigation' })

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
-- AI
----------------------------------------

-- , + a: Открывает vsplit с ai
map('n', '<leader>a', function()
  vim.cmd('botright vsplit')
  vim.cmd('vertical resize ' .. math.floor(vim.o.columns * 0.33))
  vim.cmd('terminal claude')
  vim.cmd('startinsert')
end, { desc = 'Open AI' })

----------------------------------------
-- Snacks
----------------------------------------

-- поиск файлов
map('n', '<leader>sf', function()
  Snacks.picker.files({ focus = 'list', hidden = true })
end, { desc = 'Find Files' })

-- буфферы
map('n', '<leader>sb', function()
  Snacks.picker.buffers({ focus = 'list' })
end, { desc = 'Buffer Files' })

-- недавно открытые файлы
map('n', '<leader>sr', function()
  Snacks.picker.recent({ focus = 'list', filter = { cwd = true } })
end, { desc = 'Recent Files' })

-- конфиг nvim
map('n', '<leader>sc', function()
  Snacks.picker.files({ focus = 'list', cwd = vim.fn.stdpath('config'), title = 'Config Files' })
end, { desc = 'Config Files' })

-- поиск в файлах
map('n', '<leader>sg', function()
  Snacks.picker.grep({ hidden = true })
end, { desc = 'Live Grep' })

-- поиск конкретного слова в файлах
map('x', '<leader>sg', function()
  Snacks.picker.grep_word({
    focus = 'list',
    hidden = true,
  })
end, { desc = 'Live Grep Word' })

----------------------------------------
-- Git
----------------------------------------

-- , + gs: Git stage
map('n', '<leader>gs', '<cmd>GitStageFlow<CR>', { desc = 'Git Stage Flow' })

-- , + gd: Git diff
map('n', '<leader>gd', '<cmd>DiffviewOpen<CR>', { desc = 'Git Diff Open' })

-- , + gf: Git file history
map({ 'n', 'x' }, '<leader>gf', function()
  local mode = vim.fn.mode()

  if mode == 'v' or mode == 'V' or mode == '\22' then
    -- Visual mode
    vim.cmd('normal! \27')
    vim.cmd("'<,'>DiffviewFileHistory")
  else
    -- Normal mode
    vim.cmd('DiffviewFileHistory %')
  end
end, { desc = 'Git File History' })

-- , + gp: Git project history
map('n', '<leader>gp', function()
  vim.cmd('DiffviewFileHistory')
end, { desc = 'Git Project History' })

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
-- Saving session
------------------------------------------

-- <leader> + ws: Сохранение сессии проекта
map('n', '<leader>ws', '<cmd>SaveCurrentSession<CR>', { desc = 'Save current session manually' })

-- <leader> + wl: Загрузка сессии проекта
map('n', '<leader>wl', '<cmd>LoadCurrentSession<CR>', { desc = 'Load current session manually' })

-- <leader> + wS: Показать список всех сессий для выбора
map('n', '<leader>wS', function()
  require('plugins.persistence').select()
end, { desc = 'Select or list all saved sessions' })

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
