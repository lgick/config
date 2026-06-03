----------------------------------------
-- Подсветка при копировании
----------------------------------------

vim.api.nvim_create_autocmd('TextYankPost', {
  group = vim.api.nvim_create_augroup('highlight_yank', { clear = true }),
  pattern = '*',
  desc = 'highlight selection on yank',
  callback = function()
    vim.highlight.on_yank({ timeout = 200, visual = true })
  end,
})

--------------------------------------------------------
-- Сохранение позиции курсора при открытии файла
--------------------------------------------------------

vim.api.nvim_create_autocmd('BufReadPost', {
  callback = function(args)
    local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
    local line_count = vim.api.nvim_buf_line_count(args.buf)
    if mark[1] > 0 and mark[1] <= line_count then
      vim.api.nvim_win_set_cursor(0, mark)
      vim.schedule(function()
        vim.cmd('normal! zz')
      end)
    end
  end,
})

---------------------------------------------------------------------
-- Окно справки (:help) открывается в вертикальном сплите справа
---------------------------------------------------------------------

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'help',
  command = 'wincmd L',
})

----------------------------------------------------
-- Авто-ресайз при изменении размера терминала
----------------------------------------------------

vim.api.nvim_create_autocmd('VimResized', {
  command = 'wincmd =',
})

------------------------------------------------------------------------------------------
-- Подсветка .env файлов настроек окружения (.env) как конфигурационных файлов (dosini)
------------------------------------------------------------------------------------------

vim.api.nvim_create_autocmd('BufRead', {
  group = vim.api.nvim_create_augroup('dotenv_ft', { clear = true }),
  pattern = { '.env', '.env.*' },
  callback = function()
    vim.bo.filetype = 'dosini'
  end,
})

-----------------------------------------------------------
-- Подсветка строки (cursorline) в активном окне
-----------------------------------------------------------

local cursorline_group = vim.api.nvim_create_augroup('active_cursorline', { clear = true })

-- подсветка строки (cursorline) в активном окне
vim.api.nvim_create_autocmd({ 'WinEnter', 'BufEnter' }, {
  group = cursorline_group,
  callback = function()
    vim.opt_local.cursorline = true
  end,
})

-- выключение подсветки строки (cursorline) в неактивном окне
vim.api.nvim_create_autocmd({ 'WinLeave', 'BufLeave' }, {
  group = cursorline_group,
  callback = function()
    vim.opt_local.cursorline = false
  end,
})

-----------------------------------------------------------
-- Изменение цвета в Insert Mode
-----------------------------------------------------------

local sl_group = vim.api.nvim_create_augroup('InsertModeCustomGroup', { clear = true })

-- Автокоманда при переключении Insert mode
vim.api.nvim_create_autocmd({ 'InsertEnter', 'InsertLeave' }, {
  group = sl_group,
  pattern = '*',
  callback = function()
    vim.schedule(function()
      vim.cmd('UpdateInsertModeColor')
    end)
  end,
})

------------------------------------------------------------------------------
-- Переименование файла внутри nvim-tree с изменением его во всём проекте
------------------------------------------------------------------------------

local prev = { new_name = '', old_name = '' }

vim.api.nvim_create_autocmd('User', {
  pattern = 'NvimTreeSetup',
  callback = function()
    local events = require('nvim-tree.api').events

    events.subscribe(events.Event.NodeRenamed, function(data)
      if prev.new_name ~= data.new_name or prev.old_name ~= data.old_name then
        data = data
        Snacks.rename.on_rename_file(data.old_name, data.new_name)
      end
    end)
  end,
})

------------------
-- Статус lsp
------------------

vim.api.nvim_create_autocmd('LspProgress', {
  callback = function(event)
    -- Проверяем, что это финальный статус ('end') от сервера
    if event.data.params.value.kind == 'end' then
      local client = vim.lsp.get_client_by_id(event.data.client_id)
      local client_name = client and client.name or 'LSP'

      -- Выводим однократное сообщение внизу экрана
      vim.notify(client_name .. ' ready!', vim.log.levels.INFO)

      -- Через 3 секунды очищаем командную строку
      vim.defer_fn(function()
        vim.cmd('redraw!')
        vim.api.nvim_echo({}, false, {})
      end, 3000)
    end
  end,
})
