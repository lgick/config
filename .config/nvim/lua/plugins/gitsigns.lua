local gs = require("gitsigns")
local git_flow_active = false

local function turn_on_git_mode()
  git_flow_active = true
  vim.cmd.noh() -- Скрыть подсветку поиска (если была)
  gs.detach_all()
  gs.attach()
  print("Git Stage Flow: ON")
end

local function turn_off_git_mode()
  local windows = vim.api.nvim_list_wins() -- список существующих окон
  local keys = { "s", "S", "U", "u", "r", "R", "K", "b", "n", "p", "N", "P", "q" }

  git_flow_active = false
  gs.detach_all()

  for _, win in ipairs(windows) do
    -- Если окно валидно
    if vim.api.nvim_win_is_valid(win) then
      local winhl = vim.wo[win].winhighlight

      -- Если есть нужная подсветка
      if winhl:match("StatusLine:GitSignsStatusLine") then
        -- Буфер текущего окна
        local bnr = vim.api.nvim_win_get_buf(win)

        if vim.api.nvim_buf_is_valid(bnr) then
          vim.bo[bnr].modifiable = true

          for _, key in ipairs(keys) do
            pcall(vim.keymap.del, "n", key, { buffer = bnr })
          end
        end

        -- Удаление подсветки, сохраняя остальные правила
        local parts = vim.split(winhl, ",")
        local new_parts = {}

        for _, part in ipairs(parts) do
          if part ~= "StatusLine:GitSignsStatusLine" then
            table.insert(new_parts, part)
          end
        end

        local new_winhl = table.concat(new_parts, ",")
        vim.wo[win].winhighlight = new_winhl
      end
    end
  end

  print("Git Stage Flow: OFF")
end

-- Временная разблокировка для редактирования
local function do_with_modify(bnr, action)
  return function()
    vim.bo[bnr].modifiable = true
    action()

    vim.defer_fn(function()
      vim.bo[bnr].modifiable = false
    end, 200)
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

    -- Подсветка во всех окнах с текущим файлом
    local windows = vim.api.nvim_list_wins() -- Все окна
    for _, win in ipairs(windows) do
      if vim.api.nvim_win_is_valid(win) then
        -- Если окно отображает именно этот буфер, применяем подсветку
        if vim.api.nvim_win_get_buf(win) == bufnr then
          vim.wo[win].winhighlight = "StatusLine:GitSignsStatusLine"
        end
      end
    end

    local win = vim.api.nvim_get_current_win() -- Текущее окно
    vim.wo[win].winhighlight = "StatusLine:GitSignsStatusLine"
    vim.bo[bufnr].modifiable = false

    -- KEYMAPS
    -- УПРАВЛЕНИЕ ИНДЕКСОМ (STAGE) --
    vim.keymap.set("n", "s", gs.stage_hunk, opts) -- фрагмент в/из индекса
    vim.keymap.set("n", "S", gs.stage_buffer, opts) -- файл в индекс
    vim.keymap.set("n", "U", gs.reset_buffer_index, opts) -- файл из индекса

    -- ОТМЕНА ДЕЙСТВИЙ (UNDO) --
    vim.keymap.set(
      "n",
      "u",
      do_with_modify(bufnr, function()
        vim.cmd("undo")
      end),
      opts
    )

    -- СБРОС ИЗМЕНЕНИЙ (RESET) --
    vim.keymap.set("n", "r", do_with_modify(bufnr, gs.reset_hunk), opts) -- откат правок из текущего фрагмента
    vim.keymap.set("n", "R", do_with_modify(bufnr, gs.reset_buffer), opts) -- откат всех правок файла

    -- Превью старого кода
    vim.keymap.set("n", "K", gs.preview_hunk, opts)

    -- Blame line
    vim.keymap.set("n", "b", gs.blame_line, opts)

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
  end,
})

-- Команда переключения gitsigns
vim.api.nvim_create_user_command("GitStageFlow", function()
  if git_flow_active then
    turn_off_git_mode()
  else
    turn_on_git_mode()
  end
end, { desc = "Toggle Git Stage Flow" })

-- Смена буфера (отключение gitsigns)
vim.api.nvim_create_autocmd("BufLeave", {
  group = vim.api.nvim_create_augroup("GitStageFlowCleanup", { clear = true }),
  callback = function()
    if git_flow_active then
      turn_off_git_mode()
    end
  end,
})
