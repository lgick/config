local actions = require('diffview.config').actions

local function open_file()
  local view = require('diffview.lib').get_current_view()

  if not view or not view.panel:is_focused() then
    return
  end

  local item = view.panel:get_item_at_cursor()

  if not item or item.files then
    return
  end

  actions.select_entry()
end

local function restore_with_confirm()
  local answer = vim.fn.input('Restore this file? (y/n): ')

  vim.cmd('redraw!')
  vim.api.nvim_echo({}, false, {})

  if answer:lower() == 'y' then
    vim.schedule(function()
      actions.restore_entry()
    end)
  end
end

require('diffview').setup({
  enhanced_diff_hl = true,
  file_panel = {
    listing_style = 'list',

    win_config = {
      position = 'bottom',
      height = 20,
    },
  },
  file_history_panel = {
    win_config = {
      height = 20,
    },
  },
  view = {
    default = {
      disable_diagnostics = true, -- Отключение ошибок LSP в диффах
      winbar_info = false, -- Плашки "a/файл" и "b/файл" сверху
    },
  },
  hooks = {
    view_closed = function()
      -- Обновление дерева nvim-tree (статусы git)
      local success, api = pcall(require, 'nvim-tree.api')
      if success then
        api.tree.reload()
      end
    end,
  },
  keymaps = {
    disable_defaults = true, -- Disable the default keymaps
    view = {
      { 'n', 'q', '<cmd>DiffviewClose<CR>', { desc = 'Close Diffview' } },
      { 'n', '?', actions.help({ 'view' }), { desc = 'Open the help panel' } },
      { 'n', 'f', actions.toggle_files, { desc = 'Toggle file panel' } },
    },
    file_panel = {
      { 'n', 'q', '<cmd>DiffviewClose<CR>', { desc = 'Close Diffview' } },
      { 'n', '<CR>', open_file, { desc = 'Open file' } },
      { 'n', 'f', actions.toggle_files, { desc = 'Toggle file panel' } },
      { 'n', 'o', actions.toggle_fold, { desc = 'Toggle directory' } },
      { 'n', 'R', restore_with_confirm, { desc = 'Restore file to state from selected entry' } },
      { 'n', '<C-u>', actions.scroll_view(-0.25), { desc = 'Scroll the view up' } },
      { 'n', '<C-d>', actions.scroll_view(0.25), { desc = 'Scroll the view down' } },
      { 'n', 'j', actions.next_entry, { desc = 'diffview_ignore' } },
      { 'n', 'k', actions.prev_entry, { desc = 'diffview_ignore' } },

      { 'n', 's', actions.toggle_stage_entry, { desc = 'Stage/unstage the selected entry' } },
      { 'n', 'S', actions.stage_all, { desc = 'Stage all entries' } },
      { 'n', 'U', actions.unstage_all, { desc = 'Unstage all entries' } },
      { 'n', '?', actions.help('file_panel'), { desc = 'Open the help panel' } },
    },
    file_history_panel = {
      { 'n', 'q', '<Cmd>DiffviewClose<CR>', { desc = 'Close Diffview' } },
      { 'n', '<CR>', open_file, { desc = 'Open file' } },
      { 'n', 'f', actions.toggle_files, { desc = 'Toggle file panel' } },
      { 'n', 'o', actions.toggle_fold, { desc = 'Toggle directory' } },
      { 'n', 'R', restore_with_confirm, { desc = 'Restore file to state from selected entry' } },
      { 'n', '<C-u>', actions.scroll_view(-0.25), { desc = 'Scroll the view up' } },
      { 'n', '<C-d>', actions.scroll_view(0.25), { desc = 'Scroll the view down' } },
      { 'n', 'j', actions.next_entry, { desc = 'diffview_ignore' } },
      { 'n', 'k', actions.prev_entry, { desc = 'diffview_ignore' } },

      { 'n', 'K', actions.open_commit_log, { desc = 'Show commit details' } },
      { 'n', '?', actions.help('file_history_panel'), { desc = 'Open the help panel' } },
      { 'n', '!', actions.options, { desc = 'Open the option panel' } },
    },
    option_panel = {
      { 'n', 'q', actions.close, { desc = 'Close the panel' } },
      { 'n', '?', actions.help('option_panel'), { desc = 'Open the help panel' } },
      { 'n', '<CR>', actions.select_entry, { desc = 'Change the current option' } },
    },
    help_panel = {
      { 'n', 'q', actions.close, { desc = 'Close help menu' } },
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

    vim.keymap.set('n', 'q', function()
      vim.cmd('GitStageFlow')
    end, opts)

    update_statusline_color(buf)
    callback()
  end)
end

local function turn_off_git_mode(callback)
  local keys = { 's', 'S', 'U', 'u', '<C-r>', 'r', 'R', 'K', 'n', 'N', 'p', 'P', 'w', 'q' }

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
