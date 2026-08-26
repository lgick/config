-- Форматтер markdown-таблиц. Реализация и описание контракта - в lua/md-table/.
require('md-table').setup({
  -- Спецсимволы разметки (**, `, ссылки) участвуют в расчёте ширины: в файле
  -- таблица выравнивается по "сырой" ширине, как её видят prettier, git diff
  -- и GitHub, а conceal на экране компенсирует render-markdown
  -- (pipe_table.cell = 'padded').
  ignore_markdown_syntax = false,

  -- ДОЛЖНО совпадать с printWidth в ~/.prettierrc.mjs
  max_width = 80,

  -- Колонка, чья самая высокая ячейка занимает 3 строки и больше, расширяется
  -- до 20 символов (но не шире своего содержимого).
  min_wrapped_width = 20,
  min_wrapped_lines = 3,

  -- Линия между логическими строками: true | 'multiline' | false
  row_separators = true,
})
