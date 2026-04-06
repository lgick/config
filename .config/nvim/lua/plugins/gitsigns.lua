local gs = require("gitsigns")

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
    virt_text_pos = "eol", -- Позиция текста: в конце строки (eol), поверх или справа
    delay = 1000, -- Задержка перед появлением текста (в мс)
    ignore_whitespace = false, -- Игнорировать пробелы при определении автора
    virt_text_priority = 100, -- Приоритет отображения виртуального текста
    use_focus = true, -- Показывать blame только когда окно в фокусе
  },

  current_line_blame_formatter = "<author>, <author_time:%R> - <summary>", -- Формат строки blame
  sign_priority = 6, -- Приоритет значков (если есть другие плагины в gutter)
  update_debounce = 100, -- Частота обновления значков при вводе текста
  --status_formatter = nil, -- Функция для форматирования строки статуса (lualine и т.д.)
  max_file_length = 40000, -- Отключать плагин, если в файле больше строк, чем указано
})

-- === СОСТОЯНИЕ РЕЖИМА ===
local git_flow_state = {
  active = false,
  bufnr = nil,
  orig_modifiable = nil,
}

-- Обертка для действий, которые меняют текст (Откат изменений).
-- Временная разблокировка
local function do_with_modify(bnr, action)
  return function()
    if not git_flow_state.active or git_flow_state.bufnr ~= bnr then
      return
    end

    vim.bo[bnr].modifiable = true
    action()

    -- Плагин применит правки перед тем как снова заблокировать
    vim.defer_fn(function()
      if git_flow_state.active and git_flow_state.bufnr == bnr then
        vim.bo[bnr].modifiable = false
      end
    end, 200)
  end
end

local function set_git_mappings(bnr)
  local opts = { buffer = bnr, nowait = true, silent = true }

  -- УПРАВЛЕНИЕ ИНДЕКСОМ (STAGE) --
  vim.keymap.set("n", "s", gs.stage_hunk, opts) -- фрагмент в/из индекса
  vim.keymap.set("n", "S", gs.stage_buffer, opts) -- файл в индекс
  vim.keymap.set("n", "U", gs.reset_buffer_index, opts) -- файл из индекса

  -- ОТМЕНА ДЕЙСТВИЙ (UNDO) --
  vim.keymap.set(
    "n",
    "u",
    do_with_modify(bnr, function()
      vim.cmd("undo")
    end),
    opts
  )

  -- СБРОС ИЗМЕНЕНИЙ (RESET) --
  vim.keymap.set("n", "r", do_with_modify(bnr, gs.reset_hunk), opts) -- откат правок из текущего фрагмента
  vim.keymap.set("n", "R", do_with_modify(bnr, gs.reset_buffer), opts) -- откат всех правок файла

  -- Превью старого кода
  vim.keymap.set("n", "i", gs.preview_hunk, opts)

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
end

local function remove_git_mappings(bnr)
  local keys = { "s", "S", "U", "u", "r", "R", "i", "n", "p", "N", "P", "q" }
  for _, key in ipairs(keys) do
    pcall(vim.keymap.del, "n", key, { buffer = bnr })
  end
end

-- === ВЫКЛЮЧЕНИЕ ПЛАГИНА ===
local function turn_off_git_mode()
  if not git_flow_state.active then
    return
  end

  gs.toggle_numhl(false)
  gs.toggle_linehl(false)
  gs.toggle_word_diff(false)

  local bnr = git_flow_state.bufnr

  if bnr and vim.api.nvim_buf_is_valid(bnr) then
    remove_git_mappings(bnr)
    -- Если это обычный файл с кодом (buftype == "")
    if vim.bo[bnr].buftype == "" then
      vim.bo[bnr].modifiable = true
    else
      -- Если это был какой-то спец. буфер, возвращаем как было
      vim.bo[bnr].modifiable = git_flow_state.orig_modifiable
    end
  end

  git_flow_state.active = false
  git_flow_state.bufnr = nil
  print("Git Stage Flow: OFF")
end

-- === ВКЛЮЧЕНИЕ ПЛАГИНА ===
local function turn_on_git_mode()
  local bnr = vim.api.nvim_get_current_buf()

  if vim.bo[bnr].buftype ~= "" then
    print("Git Stage Flow: Disabled for special buffers")
    return
  end

  if git_flow_state.active then
    turn_off_git_mode()
  end

  -- Сохранение текущего состояния файла
  git_flow_state.active = true
  git_flow_state.bufnr = bnr
  git_flow_state.orig_modifiable = vim.bo[bnr].modifiable

  -- Блокировка любых ручных изменений в файле (Read-Only)
  vim.bo[bnr].modifiable = false

  -- Скрыть подсветку поиска (если была)
  vim.cmd.noh()

  gs.toggle_numhl(true)
  gs.toggle_linehl(true)
  gs.toggle_word_diff(true)

  set_git_mappings(bnr)

  print("Git Stage Flow: ON")
end

-- === КОМАНДА ЗАПУСКА ===
vim.api.nvim_create_user_command("GitStageFlow", function()
  if git_flow_state.active then
    turn_off_git_mode()
  else
    turn_on_git_mode()
  end
end, { desc = "Toggle Git Stage Flow" })

-- Закрываем плагин при смене буфера
vim.api.nvim_create_autocmd("BufLeave", {
  group = vim.api.nvim_create_augroup("GitStageFlowCleanup", { clear = true }),
  callback = function(args)
    if git_flow_state.active and git_flow_state.bufnr == args.buf then
      turn_off_git_mode()
    end
  end,
})
