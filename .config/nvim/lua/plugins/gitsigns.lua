local function set_git_mappings(bnr, gs)
  -- buffer = bnr: привязка только к текущему файлу
  -- nowait = true: мгновенное срабатывание без задержек Vim
  local opts = { buffer = bnr, nowait = true, silent = true }

  -- --- УПРАВЛЕНИЕ ИНДЕКСОМ (STAGE) ---
  -- Добавляет текущий кусок кода в индекс (git add)
  vim.keymap.set("n", "s", gs.stage_hunk, opts)
  -- Добавляет файл в индекс (git add)
  vim.keymap.set("n", "S", gs.stage_buffer, opts)
  -- Убирает весь файл из индекса (Безопасный Git Reset файла)
  vim.keymap.set("n", "U", gs.reset_buffer_index, opts)
  -- Отменяет последнее действие (Undo)
  --vim.keymap.set("n", "u", "u", opts)

  -- --- СБРОС ИЗМЕНЕНИЙ (RESET) ---
  -- Удаляет правки в текущем куске (Откат к версии из Git)
  vim.keymap.set("n", "r", gs.reset_hunk, opts)
  -- Полностью сбрасывает все правки (Hard Reset)
  vim.keymap.set("n", "R", gs.reset_buffer, opts)

  -- Показывает старый код текущего куска
  vim.keymap.set("n", "i", gs.preview_hunk_inline, opts)

  -- Следующее изменение
  vim.keymap.set("n", "n", function()
    gs.nav_hunk("next")
  end, opts)

  -- Предыдущее изменение
  vim.keymap.set("n", "p", function()
    gs.nav_hunk("prev")
  end, opts)

  -- Выход из режима Git
  vim.keymap.set("n", "q", "<leader>gg", { buffer = bnr, remap = true, nowait = true })
end

local function remove_git_mappings(bnr)
  local keys = { "s", "S", "U", "r", "R", "i", "n", "p", "q" }

  for _, key in ipairs(keys) do
    pcall(vim.keymap.del, "n", key, { buffer = bnr })
  end
end

local my_signs = {
  add = { text = "\u{2590}" }, -- ▏ (новые)
  change = { text = "\u{2590}" }, -- ▐ (измененные)
  delete = { text = "\u{2590}" }, -- ◦ (удаленные)
  topdelete = { text = "\u{25e6}" }, -- ◦ (удаленные в начале файла)
  changedelete = { text = "\u{25cf}" }, -- ● (изменения с удалением)
  untracked = { text = "\u{25cb}" }, -- ○ (не отслеживаемые git)
}

require("gitsigns").setup({
  signs = my_signs,
  signs_staged = my_signs,

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
  status_formatter = nil, -- Функция для форматирования строки статуса (lualine и т.д.)
  max_file_length = 40000, -- Отключать плагин, если в файле больше строк, чем указано
  preview_config = {
    style = "minimal",
    relative = "cursor",
    row = 0,
    col = 1,
  },
})

local git_mode_active = false

vim.api.nvim_create_user_command("GitStageFlow", function()
  local gs = require("gitsigns")
  local bufnr = vim.api.nvim_get_current_buf()

  gs.toggle_signs()
  gs.toggle_linehl()

  git_mode_active = not git_mode_active

  if git_mode_active then
    set_git_mappings(bufnr, gs)
    print("Git Stage Flow: ON")
  else
    remove_git_mappings(bufnr)
    print("Git Stage Flow: OFF")
  end
end, { desc = "Git Stage Flow" })

vim.api.nvim_create_autocmd("BufLeave", {
  group = vim.api.nvim_create_augroup("GitStageFlowCleanup", { clear = true }),
  callback = function()
    if git_mode_active then
      vim.cmd("GitStageFlow")
    end
  end,
})
