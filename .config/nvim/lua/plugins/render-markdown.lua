require('render-markdown').setup({
  anti_conceal = {
    enabled = false, -- Отключает раскрытие кода под курсором
  },

  heading = {
    width = 'block',
    icons = { '', '', '', '', '', '' },
    sign = false,
    right_pad = 2,
    left_margin = 0,
  },

  pipe_table = {
    enabled = true,
    preset = 'round', -- скруглённые углы рамки
    style = 'full', -- верхняя и нижняя границы
    -- padded: ширина колонки считается по ВИДИМОЙ ширине ячейки (после
    -- скрытия **, `, ссылок), недостающее добирается виртуальным отступом.
    -- Поэтому разметка в ячейке не перекашивает колонки.
    cell = 'padded',
    padding = 1,
  },
})
