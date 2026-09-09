-- Виртуальный рендерер markdown-таблиц (GitHub-style) для Neovim.
local M = {}

-- Настройки по умолчанию
M.config = {
  border = 'none', -- Стиль рамок: 'ascii' | 'rounded' | 'single' | 'double' | 'github' | 'none'
  padding_top = 1, -- Внутренний отступ сверху внутри каждой строки (число пустых строк)
  padding_bottom = 1, -- Внутренний отступ снизу внутри каждой строки (число пустых строк)
  header_padding_top = nil, -- Отдельный отступ сверху для шапки (nil - брать из padding_top)
  header_padding_bottom = nil, -- Отдельный отступ снизу для шапки (nil - брать из padding_bottom)
  margin_top = 0, -- Внешний отступ перед таблицей (пустые строки от текста)
  margin_bottom = 0, -- Внешний отступ после таблицы (пустые строки до текста)
  min_wrapped_width = 16, -- Минимальная ширина колонки для текста с переносом
  min_wrapped_lines = 3, -- Порог строк, при котором узкая колонка пытается расшириться
  max_width = nil, -- Максимальная ширина таблицы (nil - по ширине окна)
}

-- Символы для построения границ таблицы
local BORDER_STYLES = {
  rounded = {
    top = { '╭─', '─┬─', '─╮' },
    sep = { '├─', '─┼─', '─┤' },
    bot = { '╰─', '─┴─', '─╯' },
    vert = '│',
    horiz = '─',
  },
  single = {
    top = { '┌─', '─┬─', '─┐' },
    sep = { '├─', '─┼─', '─┤' },
    bot = { '└─', '─┴─', '─┘' },
    vert = '│',
    horiz = '─',
  },
  double = {
    top = { '╔═', '═╦═', '═╗' },
    sep = { '╠═', '═╬═', '═╣' },
    bot = { '╚═', '═╩═', '═╝' },
    vert = '║',
    horiz = '═',
  },
  github = {
    top = nil,
    sep = { '──', '─┼─', '──' },
    bot = nil,
    vert = '│',
    horiz = '─',
  },
  ascii = {
    top = { '+-', '-+-', '-+' },
    sep = { '+-', '-+-', '-+' },
    bot = { '+-', '-+-', '-+' },
    vert = '|',
    horiz = '-',
  },
  none = { top = nil, sep = { '  ', '   ', '  ' }, bot = nil, vert = ' ', horiz = ' ' },
}

--------------------------------------------------------------------------------
-- Утилиты и обработка текста
--------------------------------------------------------------------------------

-- Удаление пробелов по краям строки
local function trim(s)
  return (s:gsub('^%s+', ''):gsub('%s+$', ''))
end

-- Кэш расчёта экранной ширины текста (с учётом UTF-8 и CJK)
local width_cache = {}
local function vis_width(str)
  if not str or str == '' then
    return 0
  end
  local w = width_cache[str]
  if not w then
    w = vim.fn.strdisplaywidth(str)
    width_cache[str] = w
  end
  return w
end

-- Очистка текста ячейки от разметки Markdown
local function clean_markdown_inlines(text)
  text = text
    :gsub('\\|', '|') -- Экранированный пайп \| -> |
    :gsub('`([^`]+)`', '%1') -- Инлайн-код `code` -> code
    :gsub('%[([^%]]-)%]%([^%)]-%)', '%1') -- Ссылки [label](url) -> label
    :gsub('~~([^~]+)~~', '%1') -- Зачёркивание ~~text~~ -> text
    :gsub('%*%*%*([^*]+)%*%*%*', '%1') -- Жирный+курсив ***text*** -> text
    :gsub('%*%*([^*]+)%*%*', '%1') -- Жирный **text** -> text
    :gsub('%*([^*]+)%*', '%1') -- Курсив *text* -> text

  -- Подчёркивания удаляются ТОЛЬКО на границах слов (сохраняет CONSTANT_NAMES и snake_case)
  local s = ' ' .. text .. ' '
  s = s:gsub('([^%w])___([^_]+)___([^%w])', '%1%2%3')
    :gsub('([^%w])__([^_]+)__([^%w])', '%1%2%3')
    :gsub('([^%w])_([^_]+)_([^%w])', '%1%2%3')
  return s:sub(2, -2)
end

-- Разбиение строки таблицы на ячейки с учётом экранирования \|
local function split_row(line)
  local cells, from, escaped = {}, nil, false
  for i = 1, #line do
    local c = line:sub(i, i)
    if escaped then
      escaped = false
    elseif c == '\\' then
      escaped = true
    elseif c == '|' then
      if from then
        cells[#cells + 1] = trim(line:sub(from, i - 1))
      end
      from = i + 1
    end
  end
  return cells
end

-- Проверка, является ли строка буфера строкой таблицы (|...|)
local function is_table_line(line)
  local t = trim(line)
  return #t > 1 and t:sub(1, 1) == '|' and t:sub(-1, -1) == '|'
end

-- Проверка, является ли строка разделителем заголовка (|:---:|:---|)
local function is_separator_row(cells)
  if #cells == 0 then
    return false
  end
  for _, c in ipairs(cells) do
    if not c:match('^:?%-+:?$') then
      return false
    end
  end
  return true
end

-- Чтение выравнивания колонок (:--: -> center, :-- -> left, --: -> right)
local function read_alignments(cells)
  local aligns = {}
  for i, c in ipairs(cells) do
    local l, r = c:sub(1, 1) == ':', c:sub(-1, -1) == ':'
    aligns[i] = (l and r and 'center') or (l and 'left') or (r and 'right') or 'default'
  end
  return aligns
end

--------------------------------------------------------------------------------
-- Перенос текста и расчёт ширин колонок
--------------------------------------------------------------------------------

-- Безопасный перенос длинного текста по словам (с разбиением слишком длинных слов)
local function wrap_text(text, max_w)
  if vis_width(text) <= max_w then
    return { text }
  end
  local lines, cur_words, cur_w = {}, {}, 0

  for word in text:gmatch('%S+') do
    local w = vis_width(word)
    if w > max_w then -- Слово шире колонки: разбиваем посимвольно
      if #cur_words > 0 then
        lines[#lines + 1] = table.concat(cur_words, ' ')
        cur_words, cur_w = {}, 0
      end
      local chunk = ''
      for _, char in ipairs(vim.fn.str2list(word)) do
        local ch = vim.fn.nr2char(char)
        if vis_width(chunk .. ch) > max_w and chunk ~= '' then
          lines[#lines + 1] = chunk
          chunk = ch
        else
          chunk = chunk .. ch
        end
      end
      if chunk ~= '' then
        cur_words[1] = chunk
        cur_w = vis_width(chunk)
      end
    elseif cur_w + (cur_w > 0 and 1 or 0) + w <= max_w then
      cur_words[#cur_words + 1] = word
      cur_w = cur_w + (cur_w > 0 and 1 or 0) + w
    else
      lines[#lines + 1] = table.concat(cur_words, ' ')
      cur_words = { word }
      cur_w = w
    end
  end

  if #cur_words > 0 then
    lines[#lines + 1] = table.concat(cur_words, ' ')
  end
  return #lines > 0 and lines or { '' }
end

-- Пропорциональное распределение ширины окна между колонками таблицы
local function calculate_widths(natural, max_word, available, texts, max_cols)
  local N = #natural
  local total_nat = 0
  for i = 1, N do
    total_nat = total_nat + natural[i]
  end
  if total_nat <= available then
    return vim.deepcopy(natural)
  end

  -- Минимально необходимые ширины для каждого столбца
  local target, mins, sum_min = {}, {}, 0
  for i = 1, N do
    local m = math.max(math.min(max_word[i] or 3, 20), 3)
    mins[i] = math.min(m, natural[i])
    sum_min = sum_min + mins[i]
  end

  -- Если места меньше минимума — сжимаем пропорционально
  if sum_min >= available then
    local factor, alloc = available / math.max(sum_min, 1), 0
    for i = 1, N do
      target[i] = math.max(math.floor(mins[i] * factor), 3)
      alloc = alloc + target[i]
    end
    for i = 1, (available - alloc) do
      target[i] = target[i] + 1
    end
    return target
  end

  -- Распределяем оставшееся свободное пространство окна
  for i = 1, N do
    target[i] = mins[i]
  end
  local rem = available - sum_min
  local extra_nat, active = 0, {}
  for i = 1, N do
    if natural[i] > target[i] then
      extra_nat = extra_nat + (natural[i] - target[i])
      active[#active + 1] = i
    end
  end

  if extra_nat > 0 and rem > 0 then
    local to_dist = rem
    for _, i in ipairs(active) do
      local added = math.floor(((natural[i] - target[i]) / extra_nat) * to_dist)
      target[i] = target[i] + added
      rem = rem - added
    end
    for i = 1, rem do
      target[active[(i - 1) % #active + 1]] = target[active[(i - 1) % #active + 1]] + 1
    end
  end

  -- Комфортная ширина: предотвращаем сильное сжатие колонок в «столбики»
  if M.config.min_wrapped_width > 0 then
    for c = 1, max_cols do
      local tw = target[c]
      if tw < M.config.min_wrapped_width and (natural[c] or 0) > tw then
        local h = 1
        for _, r in ipairs(texts) do
          h = math.max(h, #wrap_text(r[c] or '', tw))
        end
        if h >= M.config.min_wrapped_lines then
          local desired = math.max(tw, math.min(natural[c], M.config.min_wrapped_width))
          local diff = desired - tw
          local cur_sum = 0
          for i = 1, max_cols do
            cur_sum = cur_sum + target[i]
          end
          if cur_sum + diff <= available then
            target[c] = desired
          end
        end
      end
    end
  end

  return target
end

--------------------------------------------------------------------------------
-- Отрисовка виртуальной таблицы
--------------------------------------------------------------------------------

-- Поиск блоков таблиц в тексте буфера (игнорирует блоки кода ```)
local function find_table_blocks(lines)
  local blocks, in_tbl, start_l, tbl_lines, fence = {}, false, nil, {}, nil
  local function close(e)
    if in_tbl then
      blocks[#blocks + 1] = { start_line = start_l, end_line = e, lines = tbl_lines }
      in_tbl, tbl_lines = false, {}
    end
  end

  for i, l in ipairs(lines) do
    local t = trim(l)
    local fnc = t:match('^(```+)') or t:match('^(~~~+)')
    if fence then
      if fnc and fnc:sub(1, 1) == fence:sub(1, 1) and #fnc >= #fence then
        fence = nil
      end
    elseif fnc then
      close(i - 1)
      fence = fnc
    elseif is_table_line(l) then
      if not in_tbl then
        in_tbl, start_l, tbl_lines = true, i, {}
      end
      tbl_lines[#tbl_lines + 1] = l
    else
      close(i - 1)
    end
  end
  close(#lines)
  return blocks
end

-- Построение горизонтальной рамки (верхней, разделителя или нижней)
local function make_border_line(b_style, b_type, col_widths, indent)
  local def = b_style[b_type]
  if not def then
    return nil
  end
  local parts = {}
  for _, w in ipairs(col_widths) do
    parts[#parts + 1] = string.rep(b_style.horiz, w)
  end
  return { { indent .. def[1] .. table.concat(parts, def[2]) .. def[3], 'MdTableBorder' } }
end

-- Генерация всех виртуальных строк таблицы для одного блока
local function render_virtual_table(buf, block, total_width)
  local lines = block.lines
  local sep_cells = split_row(lines[2] or '')
  if #lines < 2 or not is_separator_row(sep_cells) then
    return nil
  end

  local separator_idx = 2
  local alignments = read_alignments(sep_cells)
  local b_style = BORDER_STYLES[M.config.border] or BORDER_STYLES.ascii
  local indent = lines[1]:match('^(%s*)') or ''

  -- Извлечение ячеек строк
  local raw_rows, max_cols = {}, 0
  for idx = 1, #lines do
    if idx ~= separator_idx then
      local cells = {}
      for c_idx, ct in ipairs(split_row(lines[idx])) do
        cells[c_idx] = clean_markdown_inlines(ct)
      end
      max_cols = math.max(max_cols, #cells)
      raw_rows[#raw_rows + 1] = {
        row = block.start_line - 1 + idx - 1,
        len = #lines[idx],
        is_header = (idx < separator_idx),
        cells = cells,
      }
    end
  end
  if max_cols == 0 then
    return nil
  end

  local available = math.max(total_width - vis_width(indent) - (3 * max_cols + 1), max_cols * 3)
  local natural_w, max_word_w, texts = {}, {}, {}

  -- Расчёт естественных длин текста ячеек
  for _, r in ipairs(raw_rows) do
    local rt = {}
    for c = 1, max_cols do
      local t = r.cells[c] or ''
      rt[c] = t
      natural_w[c] = math.max(natural_w[c] or 3, vis_width(t))
      local mw = 0
      for w in t:gmatch('%S+') do
        mw = math.max(mw, vis_width(w))
      end
      max_word_w[c] = math.max(max_word_w[c] or 0, mw)
    end
    texts[#texts + 1] = rt
  end

  local target_w = calculate_widths(natural_w, max_word_w, available, texts, max_cols)

  -- Форматирование содержимого ячейки с учётом выравнивания и фона
  local function put(str, width, align, out, hl_def)
    local cw = vis_width(str)
    local pad = math.max(0, width - cw)
    local left = (align == 'right' and pad) or (align == 'center' and math.floor(pad / 2)) or 0
    if left > 0 then
      out[#out + 1] = { string.rep(' ', left), hl_def }
    end
    if str ~= '' then
      out[#out + 1] = { str, hl_def }
    end
    if pad - left > 0 then
      out[#out + 1] = { string.rep(' ', pad - left), hl_def }
    end
  end

  -- Сборка всей визуальной строки (рамки + ячейки со сплошным фоном)
  local function emit_row(get_cell, hl_def)
    local out = {}
    if indent ~= '' then
      out[#out + 1] = { indent, hl_def }
    end
    out[#out + 1] = { b_style.vert, 'MdTableBorder' }
    out[#out + 1] = { ' ', hl_def }
    for c = 1, max_cols do
      if c > 1 then
        out[#out + 1] = { ' ', hl_def }
        out[#out + 1] = { b_style.vert, 'MdTableBorder' }
        out[#out + 1] = { ' ', hl_def }
      end
      get_cell(c, target_w[c], out)
    end
    out[#out + 1] = { ' ', hl_def }
    out[#out + 1] = { b_style.vert, 'MdTableBorder' }
    return out
  end

  -- Сборка таблицы в один проход
  local rendered_items = {}
  local data_row_idx = 0
  local sep_inserted = false

  local sep_rendered = make_border_line(b_style, 'sep', target_w, indent)
    or emit_row(function(c, w, out)
      out[#out + 1] = { string.rep(b_style.horiz, w), 'MdTableBorder' }
    end, 'MdTableBorder')

  for _, r in ipairs(raw_rows) do
    local is_head = r.is_header
    local row_hl = 'MdTableCell'
    if is_head then
      row_hl = 'MdTableHead'
    else
      data_row_idx = data_row_idx + 1
      row_hl = (data_row_idx % 2 == 1) and 'MdTableCellOdd' or 'MdTableCellEven'
    end

    -- Вставка линии разделителя сразу после шапки
    if not is_head and not sep_inserted then
      rendered_items[#rendered_items + 1] = {
        row = block.start_line - 1 + separator_idx - 1,
        len = #lines[separator_idx],
        line = sep_rendered,
        row_hl = 'MdTableBorder',
      }
      sep_inserted = true
    end

    -- Перенос текста ячеек
    local wrapped, height = {}, 1
    for c = 1, max_cols do
      wrapped[c] = wrap_text(r.cells[c] or '', target_w[c])
      height = math.max(height, #wrapped[c])
    end

    -- Сборка строк с учётом вертикальных отступов
    local r_lines = {}
    local p_top = is_head and (M.config.header_padding_top or M.config.padding_top or 0)
      or (M.config.padding_top or 0)
    for _ = 1, p_top do
      r_lines[#r_lines + 1] = emit_row(function(c, w, out)
        put('', w, 'default', out, row_hl)
      end, row_hl)
    end
    for h = 1, height do
      r_lines[#r_lines + 1] = emit_row(function(c, w, out)
        put(wrapped[c][h] or '', w, alignments[c] or 'default', out, row_hl)
      end, row_hl)
    end
    local p_bot = is_head and (M.config.header_padding_bottom or M.config.padding_bottom or 0)
      or (M.config.padding_bottom or 0)
    for _ = 1, p_bot do
      r_lines[#r_lines + 1] = emit_row(function(c, w, out)
        put('', w, 'default', out, row_hl)
      end, row_hl)
    end

    -- Линии переноса и нижний padding выводятся через virt_lines
    local extra_virt = nil
    if #r_lines > 1 then
      extra_virt = {}
      for i = 2, #r_lines do
        extra_virt[#extra_virt + 1] = r_lines[i]
      end
    end

    rendered_items[#rendered_items + 1] = {
      row = r.row,
      len = r.len,
      line = r_lines[1],
      virt_lines = extra_virt,
      row_hl = row_hl,
    }
  end

  if not sep_inserted then
    rendered_items[#rendered_items + 1] = {
      row = block.start_line - 1 + separator_idx - 1,
      len = #lines[separator_idx],
      line = sep_rendered,
      row_hl = 'MdTableBorder',
    }
  end

  -- Верхняя и нижняя границы таблицы
  if #rendered_items > 0 then
    rendered_items[1].top_border = make_border_line(b_style, 'top', target_w, indent)
    rendered_items[#rendered_items].bot_border = make_border_line(b_style, 'bot', target_w, indent)
  end

  return rendered_items
end

--------------------------------------------------------------------------------
-- Управление extmarks и отрисовка
--------------------------------------------------------------------------------

local ns = vim.api.nvim_create_namespace('md_table_render')
local cache = {}
local applied = {}
local decorated = {}

-- Доступная ширина текстовой области окна
local function text_width(win)
  local info = vim.fn.getwininfo(win)[1]
  local win_w = info and info.width or vim.api.nvim_win_get_width(win)
  local textoff = info and (info.textoff or 0) or 0
  local w = win_w - textoff - 4
  if M.config.max_width then
    w = math.min(w, M.config.max_width)
  end
  return math.max(w, 20)
end

-- Кэширование отрендеренных таблиц буфера
local function buffer_blocks(buf, width)
  local tick = vim.api.nvim_buf_get_changedtick(buf)
  local entry = cache[buf]
  if entry and entry.tick == tick and entry.width == width then
    return entry.blocks
  end

  width_cache = {}
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local blocks = {}

  for _, block in ipairs(find_table_blocks(lines)) do
    local rendered = render_virtual_table(buf, block, width)
    if rendered then
      blocks[#blocks + 1] =
        { first = block.start_line - 1, last = block.end_line - 1, rendered = rendered }
    end
  end

  cache[buf] = { tick = tick, width = width, blocks = blocks }
  return blocks
end

-- Проверка активности рендера (отключается в режиме вставки)
local function active(win, buf)
  if
    vim.b[buf].md_table_disable
    or vim.g.md_table_disable
    or vim.bo[buf].filetype ~= 'markdown'
  then
    return false
  end
  if vim.api.nvim_get_mode().mode:match('^[iRsS\19]') and buf == vim.api.nvim_get_current_buf() then
    return false
  end
  if vim.wo[win].conceallevel < 2 then
    vim.wo[win].conceallevel = 2
  end
  if not vim.wo[win].concealcursor:find('n') then
    local cc = vim.wo[win].concealcursor
    vim.wo[win].concealcursor = (cc == '' and 'nc' or cc .. 'n')
  end
  return true
end

-- Очистка меток буфера
local function clear(buf)
  if vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  end
  applied[buf] = nil
end

-- Основной цикл обновления таблиц на экране
local function refresh()
  local seen = {}
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if not seen[buf] and active(win, buf) then
      seen[buf] = true
      local width = text_width(win)
      local ok, blocks = pcall(buffer_blocks, buf, width)
      blocks = (ok and blocks) or {}

      -- Ключ кэша для предотвращения лишней перерисовки при движении курсора
      local key = table.concat({
        vim.api.nvim_buf_get_changedtick(buf),
        width,
        M.config.border,
        tostring(M.config.padding_top),
        tostring(M.config.padding_bottom),
        tostring(M.config.margin_top),
        tostring(M.config.margin_bottom),
      }, ':')

      if applied[buf] ~= key then
        vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

        for _, block in ipairs(blocks) do
          -- Изоляция от стороннего md-conceal на строках таблицы
          vim.api.nvim_buf_clear_namespace(
            buf,
            vim.api.nvim_create_namespace('md_conceal'),
            block.first,
            block.last + 1
          )

          for _, item in ipairs(block.rendered) do
            local line_str = vim.api.nvim_buf_get_lines(buf, item.row, item.row + 1, false)[1] or ''
            local line_len = #line_str
            local row_hl = item.row_hl or 'MdTableCell'

            local chunks, virt_w = {}, 0
            for _, ch in ipairs(item.line) do
              chunks[#chunks + 1] = { ch[1], ch[2] or row_hl }
              virt_w = virt_w + vis_width(ch[1])
            end
            if line_len > virt_w then
              chunks[#chunks + 1] = { string.rep(' ', line_len - virt_w), row_hl }
            end

            -- Нижние виртуальные строки (переносы, padding_bottom, нижняя рамка, margin_bottom)
            local extra_below = nil
            if item.virt_lines or item.bot_border then
              extra_below = {}
              if item.virt_lines then
                for _, vl in ipairs(item.virt_lines) do
                  extra_below[#extra_below + 1] = vl
                end
              end
              if item.bot_border then
                extra_below[#extra_below + 1] = item.bot_border
                for _ = 1, (M.config.margin_bottom or 0) do
                  extra_below[#extra_below + 1] = { { ' ', 'Normal' } }
                end
              end
            end

            -- Верхняя рамка таблицы и margin_top
            if item.top_border then
              local top_lines = {}
              for _ = 1, (M.config.margin_top or 0) do
                top_lines[#top_lines + 1] = { { ' ', 'Normal' } }
              end
              top_lines[#top_lines + 1] = item.top_border
              pcall(
                vim.api.nvim_buf_set_extmark,
                buf,
                ns,
                item.row,
                0,
                { virt_lines = top_lines, virt_lines_above = true, priority = 2000 }
              )
            end

            -- Оверлей поверх строки буфера (conceal = '' скрывает исходную строку от разрыва терминалом)
            pcall(vim.api.nvim_buf_set_extmark, buf, ns, item.row, 0, {
              end_row = item.row,
              end_col = line_len,
              conceal = '',
              virt_text = chunks,
              virt_text_pos = 'overlay',
              hl_mode = 'replace',
              priority = 2000,
              virt_lines = extra_below,
              virt_lines_above = false,
            })
          end
        end

        applied[buf] = key
        decorated[buf] = true
      end
    end
  end

  for buf in pairs(decorated) do
    if not seen[buf] then
      clear(buf)
      decorated[buf] = nil
    end
  end
end

-- Отложенный вызов перерисовки через event loop
local scheduled = false
local function schedule()
  if scheduled then
    return
  end
  scheduled = true
  vim.schedule(function()
    scheduled = false
    pcall(refresh)
  end)
end

--------------------------------------------------------------------------------
-- Инициализация и автокоманды
--------------------------------------------------------------------------------

function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})
  schedule()
end

-- Команда переключения рендера вкл/выкл
vim.api.nvim_create_user_command('MdTableToggle', function()
  local buf = vim.api.nvim_get_current_buf()
  vim.b[buf].md_table_disable = not vim.b[buf].md_table_disable
  cache[buf] = nil
  clear(buf)
  schedule()
  vim.notify(
    vim.b[buf].md_table_disable and 'md-table: выключен' or 'md-table: включён',
    vim.log.levels.INFO
  )
end, { desc = 'Включить/выключить рендер таблиц' })

-- Команда принудительного обновления
vim.api.nvim_create_user_command('MdTableRefresh', function()
  cache, applied = {}, {}
  schedule()
end, { desc = 'Перерисовать таблицы' })

-- Автокоманды для реактивности при изменении текста, окна и курсора
local group = vim.api.nvim_create_augroup('MdTableRender', { clear = true })
vim.api.nvim_create_autocmd({
  'BufWinEnter',
  'BufEnter',
  'BufReadPost',
  'WinEnter',
  'WinResized',
  'VimResized',
  'TextChanged',
  'TextChangedI',
  'InsertEnter',
  'InsertLeave',
  'CursorMoved',
  'CursorMovedI',
  'FileType',
}, { group = group, callback = schedule })

vim.api.nvim_create_autocmd('BufDelete', {
  group = group,
  callback = function(args)
    cache[args.buf], applied[args.buf], decorated[args.buf] = nil, nil, nil
  end,
})

schedule()
return M
