local gs = require('gitsigns')
local active_buf = nil
local augroup = vim.api.nvim_create_augroup('GitStageFlowAuCmds', { clear = true })

-- Временная разблокировка для редактирования
local function do_with_modify(buf, action)
  return function()
    if not vim.api.nvim_buf_is_valid(buf) then
      return
    end

    vim.bo[buf].modifiable = true

    -- Функция, которая заблокирует буфер обратно
    local done = function()
      vim.schedule(function()
        if not vim.api.nvim_buf_is_valid(buf) then
          return
        end

        -- Сохранение, если буфер изменён
        if vim.bo[buf].modified then
          vim.cmd('silent! noautocmd update')
        end

        -- Блокировка
        vim.bo[buf].modifiable = false
      end)
    end

    -- Выполнение действия, передавая ему функцию завершения
    action(done)
  end
end

-- Изменение winhighlight
local function set_winhl(win, new_rule)
  if not vim.api.nvim_win_is_valid(win) then
    return
  end

  local current = vim.wo[win].winhighlight or ''
  local new_parts = {}

  if current ~= '' then
    for _, part in ipairs(vim.split(current, ',')) do
      -- Отсеять пустые строки и старые правила Gitsigns
      if part ~= '' and not part:match('^StatusLine:GitSignsStatusLine') then
        table.insert(new_parts, part)
      end
    end
  end

  -- Если передано новое правило
  if new_rule then
    table.insert(new_parts, new_rule)
  end

  vim.wo[win].winhighlight = table.concat(new_parts, ',')
end

-- Проверка наличия Staged-меток
local function has_staged_signs(buf)
  local namespaces = vim.api.nvim_get_namespaces()

  for name, ns_id in pairs(namespaces) do
    if name:match('gitsigns') then
      local extmarks = vim.api.nvim_buf_get_extmarks(buf, ns_id, 0, -1, { details = true })

      for _, mark in ipairs(extmarks) do
        local details = mark[4]

        if type(details) == 'table' then
          for _, v in pairs(details) do
            if type(v) == 'string' and v:match('^GitSignsStaged') then
              return true
            end
          end
        end
      end
    end
  end

  return false
end

-- Обновление названия группы подсветки statusline
local function update_statusline_color(buf)
  if not active_buf or not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  local status = vim.b[buf].gitsigns_status_dict or {}
  local has_unstaged = ((status.added or 0) + (status.changed or 0) + (status.removed or 0)) > 0
  local target_hl_group = 'GitSignsStatusLine'

  if has_unstaged then
    target_hl_group = 'GitSignsStatusLineUnstaged'
  elseif has_staged_signs(buf) then
    target_hl_group = 'GitSignsStatusLineStaged'
  end

  local target_hl_rule = 'StatusLine:' .. target_hl_group
  local win = vim.fn.bufwinid(buf)

  if win ~= -1 then
    set_winhl(win, target_hl_rule)
  end
end

local function turn_on_git_mode()
  local buf = vim.api.nvim_get_current_buf()

  -- Если файл не отслеживается Git, не включаем режим
  if not vim.b[buf].gitsigns_status_dict then
    vim.notify('Gitstager: файл не отслеживается Git', vim.log.levels.WARN)
    return
  end

  active_buf = buf -- Запоминаем наш единственный буфер

  vim.cmd.noh() -- Скрыть подсветку поиска (если была)

  gs.toggle_numhl(true)
  gs.toggle_linehl(true)
  gs.toggle_word_diff(true)

  if vim.bo[buf].modified then
    vim.cmd('silent! noautocmd update')
  end

  if vim.b[buf].original_modifiable == nil then
    vim.b[buf].original_modifiable = vim.bo[buf].modifiable
  end

  vim.bo[buf].modifiable = false

  local opts = { nowait = true, silent = true, buffer = buf }

  -- KEYMAPS
  -- УПРАВЛЕНИЕ ИНДЕКСОМ (STAGE) --
  vim.keymap.set('n', 's', gs.stage_hunk, opts) -- фрагмент в/из индекса
  vim.keymap.set('n', 'S', gs.stage_buffer, opts) -- добавляется все правки в индекс
  vim.keymap.set('n', 'U', gs.reset_buffer_index, opts) -- удаляет все правки файла из индекса

  -- ОТМЕНА ДЕЙСТВИЙ (UNDO) --
  vim.keymap.set(
    'n',
    'u',
    do_with_modify(buf, function(done)
      vim.cmd('undo')
      done() -- Команда undo синхронна, вызов done() сразу после нее
    end),
    opts
  )

  -- ВОЗВРАТ ОТМЕНЁННЫХ ДЕЙСТВИЙ (REDO) --
  vim.keymap.set(
    'n',
    '<C-r>',
    do_with_modify(buf, function(done)
      vim.cmd('redo')
      done() -- Команда redo синхронна
    end),
    opts
  )

  -- СБРОС ИЗМЕНЕНИЙ (RESET) --
  -- откат правок из текущего фрагмента
  vim.keymap.set(
    'n',
    'r',
    do_with_modify(buf, function(done)
      -- reset_hunk асинхронна. Передача done третьим аргументом (callback)
      -- Первые два аргумента (range и opts) nil, чтобы использовать дефолтные
      gs.reset_hunk(nil, nil, done)
    end),
    opts
  )

  -- откат всех правок файла
  vim.keymap.set(
    'n',
    'R',
    do_with_modify(buf, function(done)
      gs.reset_buffer()
      done() -- reset_buffer async, вызываем сразу
    end),
    opts
  )

  -- Превью старого кода
  vim.keymap.set('n', 'K', gs.preview_hunk, opts)

  -- Навигация
  vim.keymap.set('n', 'n', function()
    ---@diagnostic disable-next-line: missing-fields
    gs.nav_hunk('next')
  end, opts)
  vim.keymap.set('n', 'N', function()
    ---@diagnostic disable-next-line: missing-fields
    gs.nav_hunk('next', { target = 'all' })
  end, opts)
  vim.keymap.set('n', 'p', function()
    ---@diagnostic disable-next-line: missing-fields
    gs.nav_hunk('prev')
    vim.keymap.set('n', 'P', function()
      ---@diagnostic disable-next-line: missing-fields
      gs.nav_hunk('prev', { target = 'all' })
    end, opts)
  end, opts)

  -- Выход из режима
  vim.keymap.set('n', 'q', function()
    vim.cmd('GitStageFlow')
  end, opts)

  update_statusline_color(buf)
end

local function turn_off_git_mode()
  local keys = { 's', 'S', 'U', 'u', '<C-r>', 'r', 'R', 'K', 'n', 'p', 'N', 'P', 'q' }

  gs.toggle_numhl(false)
  gs.toggle_linehl(false)
  gs.toggle_word_diff(false)

  if active_buf and vim.api.nvim_buf_is_valid(active_buf) then
    -- Если original_modifiable установлен, значит это буфер использовался в gitstager.nvim
    if vim.b[active_buf].original_modifiable ~= nil then
      -- Сброс modifiable
      vim.bo[active_buf].modifiable = vim.b[active_buf].original_modifiable
      vim.b[active_buf].original_modifiable = nil

      local win = vim.fn.bufwinid(active_buf)

      -- Очистка подсветки
      if win ~= -1 then
        set_winhl(win, nil)
      end

      -- Удаление биндов
      for _, key in ipairs(keys) do
        pcall(vim.keymap.del, 'n', key, { buffer = active_buf })
      end
    end
  end

  active_buf = nil
end

gs.setup({
  signs_staged_enable = true, -- Включить отображение знаков для индексированных изменений
  auto_attach = true, -- Автоматически подключаться к открытым буферам
  signcolumn = false, -- Показывать значки на боковой панели (gutter)
  numhl = false, -- Подсвечивать номера строк
  linehl = false, -- Подсвечивать всю строку целиком
  word_diff = false, -- Подсвечивать внутристрочные изменения
  watch_gitdir = {
    follow_files = true, -- Следить за изменениями в .git директории
  },

  attach_to_untracked = false, -- Показывать значки для файлов вне индекса Git
  current_line_blame = false, -- Показывать автора и дату правки в текущей строке
  current_line_blame_opts = {
    virt_text = true, -- Использовать виртуальный текст для inline-blame
    virt_text_pos = 'eol', -- Позиция текста: в конце строки (eol), поверх или справа
    delay = 1000, -- Задержка перед появлением текста (в мс)
    ignore_whitespace = false, -- Игнорировать пробелы при определении автора
    virt_text_priority = 100, -- Приоритет отображения виртуального текста
    use_focus = true, -- Показывать blame только когда окно в фокусе
  },

  current_line_blame_formatter = '<author>, <author_time:%R> - <summary>', -- Формат строки blame
  sign_priority = 6, -- Приоритет значков (если есть другие плагины)
  update_debounce = 100, -- Частота обновления значков при вводе текста
  max_file_length = 40000, -- Отключать плагин, если в файле больше строк, чем указано
})

vim.api.nvim_create_autocmd('User', {
  pattern = 'GitSignsUpdate',
  group = augroup,
  callback = function(args)
    if active_buf and args.data and args.data.buffer == active_buf then
      update_statusline_color(args.data.buffer)
    end
  end,
})

-- Обновление или сброс цвета окна при переключении между файлами/сплитами
vim.api.nvim_create_autocmd({ 'BufEnter', 'WinEnter' }, {
  group = augroup,
  callback = function()
    if not active_buf then
      return
    end

    local win = vim.api.nvim_get_current_win()
    local buf = vim.api.nvim_get_current_buf()

    if buf == active_buf then
      -- Если буфер в реестре, обновляем его цвета
      update_statusline_color(buf)
    else
      -- Если мы переключились на буфер вне реестра,
      -- очищаем подсветку статус-лайна для текущего окна
      set_winhl(win, nil)
    end
  end,
})

-- Команда управления gitsigns
vim.api.nvim_create_user_command('GitStageFlow', function()
  if active_buf then
    turn_off_git_mode()
    print('Git Stage Flow: OFF')
  else
    turn_on_git_mode()
    print('Git Stage Flow: ON')
  end
end, { desc = 'Toggle Git Stage Flow' })
