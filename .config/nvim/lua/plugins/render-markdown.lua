require('render-markdown').setup({
  render_modes = { 'n', 'c', 't', 'i' },

  -- отключение anti-conceal (чтобы разметка не раскрывалась на строке курсора)
  anti_conceal = {
    enabled = false,
  },

  heading = {
    width = 'block',
    icons = { '# ', '## ', '### ', '#### ', '##### ', '###### ' },
    sign = false,
    right_pad = 2,
    left_margin = 0,
    backgrounds = {
      '@markup.heading.1',
      '@markup.heading.2',
      '@markup.heading.3',
      '@markup.heading.4',
      '@markup.heading.5',
      '@markup.heading.6',
    },
  },

  pipe_table = {
    enabled = true,
    style = 'full',
    preset = 'heavy',
    cell = 'padded',
    padding = 3,
  },

  -- отключение встроенного рендеринга ссылок (скрывается в md-conceal)
  link = {
    enabled = false,
  },

  -- отключение скрытия разделителей кода и инлайн-код
  code = {
    -- отключение скрытия бэктиков ``` в блоках кода
    conceal_delimiters = false,
    -- отключение обработки инлайн-кода `code` (скрывается в md-conceal)
    inline = false,
  },

  -- отключение скрытия HTML-комментариев
  html = {
    comment = {
      conceal = false,
    },
  },

  -- поведение скрытия курсора
  win_options = {
    conceallevel = {
      default = vim.o.conceallevel,
      rendered = 3, -- 3, чтобы скрытие (md-conceal) работало
    },
    concealcursor = {
      default = vim.o.concealcursor,
      -- 'nc', чтобы текст оставался скрытым в normal и command режимах,
      -- и скрипт md-conceal смог перепрыгивать через него по h/l/w/b:
      rendered = 'nc',
    },
  },

  indent = {
    -- иерархический отступ
    enabled = false,

    -- Количество символов сдвига вправо на каждый уровень заголовка (например, 2 пробела)
    per_level = 2,

    -- уровень начала сдвига:
    -- 1 = H1 остаётся у левого края, а под H2 сдвигается на 2, под H3 на 4 и т.д.
    -- 0 = сдвигать даже содержимое под самым первым заголовком H1
    skip_level = 0,

    -- Сдвиг самой строки заголовка вместе с блоком под ним:
    -- false = сам заголовок тоже сдвигается вправо вместе со своим содержимым
    -- true  = заголовки остаются прижаты влево, сдвигается ТОЛЬКО тело под ними
    skip_heading = false,

    -- Иконка направляющей линии для каждого уровня отступа.
    -- По умолчанию тонкая вертикальная полоска '▎'.
    -- Если полоска не нужна, а нужны просто пустые пробелы — поставьте ' ' (один пробел):
    icon = ' ',

    -- Подсветка для этой линии-отступа (по умолчанию скрывается/блекнет)
    highlight = 'Whitespace',
  },
})
