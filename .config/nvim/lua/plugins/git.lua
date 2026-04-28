require('diffview').setup({
  enhanced_diff_hl = true, -- Улучшенная подсветка диффов
  view = {
    -- Настройки по умолчанию для всех окон с кодом
    default = {
      disable_diagnostics = true, -- Отключение ошибок LSP в диффах
      winbar_info = true, -- Плашки "a/файл" и "b/файл" сверху
    },
  },
  keymaps = {
    view = {
      -- Закрывать Diffview по нажатию 'q' в окнах с кодом
      ['q'] = '<Cmd>DiffviewClose<CR>',
    },
    file_panel = {
      -- Закрывать Diffview по нажатию 'q' в панели файлов
      ['q'] = '<Cmd>DiffviewClose<CR>',
    },
    file_history_panel = {
      -- Закрывать Diffview по нажатию 'q' в панели истории коммитов
      ['q'] = '<Cmd>DiffviewClose<CR>',
    },
  },
})

local gs = require('gitsigns')
local active_buf = nil
local augroup = vim.api.nvim_create_augroup('GitStageFlowAuCmds', { clear = true })

gs.setup({
  signs_staged_enable = true, -- Включить отображение знаков для индексированных изменений
  auto_attach = false, -- Автоматически подключаться к открытым буферам
  signcolumn = false, -- Показывать значки на боковой панели (gutter)
  numhl = true, -- Подсвечивать номера строк
  linehl = true, -- Подсвечивать всю строку целиком
  word_diff = true, -- Подсвечивать внутристрочные изменения
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

-- Проверка Staged-меток
local function has_staged_signs(bnr)
  local namespaces = vim.api.nvim_get_namespaces()

  for name, ns_id in pairs(namespaces) do
    if name:match('gitsigns') then
      local extmarks = vim.api.nvim_buf_get_extmarks(bnr, ns_id, 0, -1, { details = true })

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

-- Обновление цвета
local function update_statusline_color(buf)
  if not active_buf or active_buf ~= buf then
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

local function turn_on_git_mode(callback)
  local buf = vim.api.nvim_get_current_buf()

  gs.detach_all()

  -- Подключение gitsigns к текущему буферу
  gs.attach({ bufnr = buf }, function(err)
    if err or vim.b.gitsigns_head == nil then
      vim.notify('Gitstager: file is not tracked by Git', vim.log.levels.WARN)
      return
    end

    active_buf = buf

    vim.cmd.noh() -- Скрыть подсветку поиска (если была)

    if vim.bo[buf].modified then
      vim.cmd('silent! noautocmd update')
    end

    -- Сохранение изначального состояния modifiable
    vim.b[buf].original_modifiable = vim.bo[buf].modifiable
    vim.bo[buf].modifiable = false -- Блокировка буфера

    local opts = { nowait = true, silent = true, buffer = buf }

    -- KEYMAPS
    -- УПРАВЛЕНИЕ ИНДЕКСОМ (STAGE) --
    vim.keymap.set('n', 's', gs.stage_hunk, opts) -- фрагмент в/из индекса
    vim.keymap.set('n', 'S', gs.stage_buffer, opts) -- добавляется все изменения в индекс
    vim.keymap.set('n', 'U', gs.reset_buffer_index, opts) -- удаляет все изменения файла из индекса

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
        -- reset_hunk асинхронна. Передача done третьим аргументом (done)
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
    end, opts)
    vim.keymap.set('n', 'P', function()
      ---@diagnostic disable-next-line: missing-fields
      gs.nav_hunk('prev', { target = 'all' })
    end, opts)

    vim.keymap.set('n', 'w', function()
      gs.blame_line({ full = true })
    end, opts)

    vim.keymap.set({ 'n', 'x' }, 'd', function()
      -- Получаем текущий режим
      local mode = vim.fn.mode()

      -- Если мы в визуальном режиме (обычный 'v', построчный 'V' или блочный Ctrl+V '\22')
      if mode == 'v' or mode == 'V' or mode == '\22' then
        -- 1. Принудительно выходим из визуального режима (эквивалент нажатия Esc).
        -- Это зафиксирует границы выделения в маркеры '< и '>
        vim.cmd('normal! \27')

        -- 2. Закрываем GitStageFlow
        vim.cmd('GitStageFlow')

        -- 3. Открываем историю только для выделенных строк
        vim.cmd("'<,'>DiffviewFileHistory")
      else
        -- Поведение для обычного режима (Normal mode)
        vim.cmd('GitStageFlow')
        vim.cmd('DiffviewFileHistory %')
      end
    end, opts)

    vim.keymap.set('n', 'q', function()
      gs.setqflist('all')
    end, opts)

    update_statusline_color(buf)
    callback()
  end)
end

local function turn_off_git_mode(callback)
  local keys = { 's', 'S', 'U', 'u', '<C-r>', 'r', 'R', 'K', 'n', 'p', 'N', 'P', 'w', 'd', 'q' }

  gs.detach_all()

  -- Если есть буфер и он валиден
  if active_buf and vim.api.nvim_buf_is_valid(active_buf) then
    if vim.b[active_buf].original_modifiable ~= nil then
      vim.bo[active_buf].modifiable = vim.b[active_buf].original_modifiable
      vim.b[active_buf].original_modifiable = nil

      -- Удаление биндов
      for _, key in ipairs(keys) do
        pcall(vim.keymap.del, 'n', key, { buffer = active_buf })
      end

      -- Очистка подсветки
      local win = vim.fn.bufwinid(active_buf)
      set_winhl(win, nil)

      active_buf = nil
      callback()
    end
  end
end

vim.api.nvim_create_autocmd('User', {
  pattern = 'GitSignsUpdate',
  group = augroup,
  callback = function(args)
    if args.data and args.data.buffer == active_buf then
      update_statusline_color(active_buf)
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

    if active_buf == buf then
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
  local buf = vim.api.nvim_get_current_buf()

  if active_buf then
    if active_buf == buf then
      turn_off_git_mode(function()
        print('Git Stage Flow: OFF')
      end)
    else
      turn_off_git_mode(function()
        turn_on_git_mode(function()
          print('Git Stage Flow: ON')
        end)
      end)
    end
  else
    turn_on_git_mode(function()
      print('Git Stage Flow: ON')
    end)
  end
end, { desc = 'Toggle Git Stage Flow' })
