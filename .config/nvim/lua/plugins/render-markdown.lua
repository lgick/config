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

  indent = {
    enabled = true, -- По умолчанию false
    per_level = 2, -- Количество пробелов для смещения на каждый уровень заголовка
    icon = '│ ',
  },
})
