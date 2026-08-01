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
   enabled = false,
  },
})
