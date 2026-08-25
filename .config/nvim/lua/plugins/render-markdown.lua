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
    preset = 'round', -- скруглённые углы (видны только при style = 'full')
    -- normal: без верхней/нижней рамки. Обязательно при row_separators = true
    -- в _table.lua: GFM видит промежуточный |---| как начало новой таблицы,
    -- и style = 'full' дорисовывал бы рамку на каждом разделителе
    style = 'normal',
    -- padded: ширина колонки считается по ВИДИМОЙ ширине ячейки (после
    -- скрытия **, `, ссылок), недостающее добирается виртуальным отступом.
    -- Поэтому разметка в ячейке не перекашивает колонки.
    cell = 'padded',
    padding = 1,
  },
})
