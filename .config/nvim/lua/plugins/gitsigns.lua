local gs = require("gitsigns")
local git_flow_active = false
local managed_buffers = {} -- Реестр буферов, в которых включен режим
local augroup = vim.api.nvim_create_augroup("GitStageFlowAuCmds", { clear = true })

-- Изменение winhighlight
local function set_winhl(win, new_rule)
  if not vim.api.nvim_win_is_valid(win) then
    return
  end

  local current = vim.wo[win].winhighlight or ""
  local new_parts = {}

  if current ~= "" then
    for _, part in ipairs(vim.split(current, ",")) do
      -- Отсеять пустые строки и старые правила Gitsigns
      if part ~= "" and not part:match("^StatusLine:GitSignsStatusLine") then
        table.insert(new_parts, part)
      end
    end
  end

  -- Если передано новое правило
  if new_rule then
    table.insert(new_parts, new_rule)
  end

  vim.wo[win].winhighlight = table.concat(new_parts, ",")
end

-- Проверка Staged-меток
local function has_staged_signs(bnr)
  local namespaces = vim.api.nvim_get_namespaces()

  for name, ns_id in pairs(namespaces) do
    if name:match("gitsigns") then
      local extmarks = vim.api.nvim_buf_get_extmarks(bnr, ns_id, 0, -1, { details = true })

      for _, mark in ipairs(extmarks) do
        local details = mark[4]

        if type(details) == "table" then
          for _, v in pairs(details) do
            if type(v) == "string" and v:match("^GitSignsStaged") then
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
local function update_statusline_color(bnr)
  if not git_flow_active or not vim.api.nvim_buf_is_valid(bnr) then
    return
  end

  local status = vim.b[bnr].gitsigns_status_dict or {}
  local has_unstaged = ((status.added or 0) + (status.changed or 0) + (status.removed or 0)) > 0
  local target_hl_group = "GitSignsStatusLine"

  if has_unstaged then
    target_hl_group = "GitSignsStatusLineUnstaged"
  elseif has_staged_signs(bnr) then
    target_hl_group = "GitSignsStatusLineStaged"
  end

  local target_hl_rule = "StatusLine:" .. target_hl_group

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == bnr then
      set_winhl(win, target_hl_rule)
    end
  end
end

local function turn_on_git_mode()
  git_flow_active = true
  vim.cmd.noh() -- Скрыть подсветку поиска (если была)
  gs.detach_all()
  gs.attach()
end

local function turn_off_git_mode()
  local keys = { "s", "S", "U", "u", "<C-r>", "r", "R", "K", "n", "p", "N", "P", "q" }

  git_flow_active = false
  gs.detach_all()

  -- Очистка всех затронутых буферов
  for bnr, _ in pairs(managed_buffers) do
    if vim.api.nvim_buf_is_valid(bnr) then
      if vim.b[bnr].original_modifiable ~= nil then
        vim.bo[bnr].modifiable = vim.b[bnr].original_modifiable
        vim.b[bnr].original_modifiable = nil -- очистка переменной
      else
        vim.bo[bnr].modifiable = true -- фоллбэк
      end

      -- Удаление биндов
      for _, key in ipairs(keys) do
        pcall(vim.keymap.del, "n", key, { buffer = bnr })
      end
    end
  end

  managed_buffers = {} -- Очистка реестра

  -- Очистка подсветки
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    set_winhl(win, nil)
  end
end

-- Временная разблокировка для редактирования
local function do_with_modify(bnr, action)
  return function()
    if not vim.api.nvim_buf_is_valid(bnr) then
      return
    end

    vim.bo[bnr].modifiable = true

    -- Функция, которая заблокирует буфер обратно
    local done = function()
      vim.schedule(function()
        if not vim.api.nvim_buf_is_valid(bnr) then
          return
        end

        -- Сохранение, если буфер изменён
        if vim.bo[bnr].modified then
          vim.cmd("silent! noautocmd update")
        end

        -- Блокировка
        vim.bo[bnr].modifiable = false
      end)
    end

    -- Выполнение действия, передавая ему функцию завершения
    action(done)
  end
end

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
    virt_text_pos = "eol", -- Позиция текста: в конце строки (eol), поверх или справа
    delay = 1000, -- Задержка перед появлением текста (в мс)
    ignore_whitespace = false, -- Игнорировать пробелы при определении автора
    virt_text_priority = 100, -- Приоритет отображения виртуального текста
    use_focus = true, -- Показывать blame только когда окно в фокусе
  },

  current_line_blame_formatter = "<author>, <author_time:%R> - <summary>", -- Формат строки blame
  sign_priority = 6, -- Приоритет значков (если есть другие плагины в gutter)
  update_debounce = 100, -- Частота обновления значков при вводе текста
  max_file_length = 40000, -- Отключать плагин, если в файле больше строк, чем указано
  on_attach = function(bufnr)
    local opts = { nowait = true, silent = true, buffer = bufnr }

    if vim.bo[bufnr].modified then
      vim.cmd("silent update")
    end

    managed_buffers[bufnr] = true

    -- Сохранение изначального состояния modifiable в локальную переменную буфера
    if vim.b[bufnr].original_modifiable == nil then
      vim.b[bufnr].original_modifiable = vim.bo[bufnr].modifiable
    end

    vim.bo[bufnr].modifiable = false -- Блокировка буфера

    -- KEYMAPS
    -- УПРАВЛЕНИЕ ИНДЕКСОМ (STAGE) --
    vim.keymap.set("n", "s", gs.stage_hunk, opts) -- фрагмент в/из индекса
    vim.keymap.set("n", "S", gs.stage_buffer, opts) -- добавляется все правки в индекс
    vim.keymap.set("n", "U", gs.reset_buffer_index, opts) -- удаляет все правки файла из индекса

    -- ОТМЕНА ДЕЙСТВИЙ (UNDO) --
    vim.keymap.set(
      "n",
      "u",
      do_with_modify(bufnr, function(done)
        vim.cmd("undo")
        done() -- Команда undo синхронна, вызов done() сразу после нее
      end),
      opts
    )

    -- ВОЗВРАТ ОТМЕНЁННЫХ ДЕЙСТВИЙ (REDO) --
    vim.keymap.set(
      "n",
      "<C-r>",
      do_with_modify(bufnr, function(done)
        vim.cmd("redo")
        done() -- Команда redo синхронна
      end),
      opts
    )

    -- СБРОС ИЗМЕНЕНИЙ (RESET) --
    -- откат правок из текущего фрагмента
    vim.keymap.set(
      "n",
      "r",
      do_with_modify(bufnr, function(done)
        -- reset_hunk асинхронна. Передача done третьим аргументом (callback)
        -- Первые два аргумента (range и opts) nil, чтобы использовать дефолтные
        gs.reset_hunk(nil, nil, done)
      end),
      opts
    )

    -- откат всех правок файла
    vim.keymap.set(
      "n",
      "R",
      do_with_modify(bufnr, function(done)
        gs.reset_buffer()
        done() -- reset_buffer async, вызываем сразу
      end),
      opts
    )

    -- Превью старого кода
    vim.keymap.set("n", "K", gs.preview_hunk, opts)

    -- Навигация
    vim.keymap.set("n", "n", function()
      ---@diagnostic disable-next-line: missing-fields
      gs.nav_hunk("next", { target = "all" })
    end, opts)
    vim.keymap.set("n", "N", function()
      ---@diagnostic disable-next-line: missing-fields
      gs.nav_hunk("next")
    end, opts)
    vim.keymap.set("n", "p", function()
      ---@diagnostic disable-next-line: missing-fields
      gs.nav_hunk("prev", { target = "all" })
    end, opts)
    vim.keymap.set("n", "P", function()
      ---@diagnostic disable-next-line: missing-fields
      gs.nav_hunk("prev")
    end, opts)

    -- Выход из режима
    vim.keymap.set("n", "q", function()
      vim.cmd("GitStageFlow")
    end, opts)

    vim.defer_fn(function()
      update_statusline_color(bufnr)
    end, 10)
  end,
})

vim.api.nvim_create_autocmd("User", {
  pattern = "GitSignsUpdate",
  group = augroup,
  callback = function(args)
    if args.data and args.data.buffer then
      update_statusline_color(args.data.buffer)
    end
  end,
})

-- Обновление или сброс цвета окна при переключении между файлами/сплитами
vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
  group = augroup,
  callback = function()
    if not git_flow_active then
      return
    end

    local win = vim.api.nvim_get_current_win()
    local buf = vim.api.nvim_get_current_buf()

    if managed_buffers[buf] then
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
vim.api.nvim_create_user_command("GitStageFlow", function()
  local current_buf = vim.api.nvim_get_current_buf()

  if git_flow_active then
    if managed_buffers[current_buf] then
      turn_off_git_mode()
      print("Git Stage Flow: OFF")
    else
      turn_off_git_mode()
      turn_on_git_mode()
      print("Git Stage Flow: ON")
    end
  else
    turn_on_git_mode()
    print("Git Stage Flow: ON")
  end
end, { desc = "Toggle Git Stage Flow" })
