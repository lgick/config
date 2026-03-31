require("trouble").setup({
  auto_refresh = true,
  restore_window = true, -- Возвращать фокус на предыдущее окно после закрытия
  follow = true, -- Автоматически переходить к ошибке при перемещении в списке
  indent_guides = true, -- Рисовать линии вложенности в дереве
  max_items = 200, -- Ограничение количества строк (для производительности)
  multiline = true, -- Показывать длинные сообщения об ошибках целиком

  -- Настройка внешнего вида
  icons = {
    indent = {
      top = "│ ",
      middle = "├ ",
      last = "└ ",
      fold_open = " ",
      fold_closed = " ",
      ws = "  ",
    },
  },

  -- Группировка (по умолчанию по файлам)
  groups = {
    { "filename", format = "{file} {git_status} {count}" },
  },
})

-- Вызов основных режимов Trouble
vim.keymap.set(
  "n",
  "<leader>xx",
  "<cmd>Trouble diagnostics toggle<cr>",
  { desc = "Все ошибки проекта" }
)
vim.keymap.set(
  "n",
  "<leader>xd",
  "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
  { desc = "Ошибки текущего файла" }
)
vim.keymap.set(
  "n",
  "<leader>cs",
  "<cmd>Trouble symbols toggle focus=false<cr>",
  { desc = "Структура файла (Symbols)" }
)
vim.keymap.set(
  "n",
  "gr",
  "<cmd>Trouble lsp_references toggle focus=true<cr>",
  { desc = "Где используется (References)" }
)
