-- Виртуальный рендерер markdown-таблиц (GitHub-style) для Neovim.
--
-- ОСОБЕННОСТИ:
--   * Отображение чистого текста без технической разметки и без лишней подсветки.
--   * Вертикальные отступы (padding_top, padding_bottom, margin_top, margin_bottom).
--   * Сплошная зебра-подсветка (MdTableCellOdd / MdTableCellEven) без зазоров у рамок.
--   * Полная защита от разрыва длинных строк Markdown терминалом при wrap = true.
--   * Изолированный рендер без смазывания и просвечивания подсветки буфера.
--   * Точный расчёт ширины колонок по чистому отображаемому тексту.
--   * Поддерживает центрирование (:--:) и выравнивание колонок.
--   * В Insert/Replace режиме рендер отключается (чистый исходный Markdown).
--   * Сплошные рамки (ascii, rounded, single, double, github, none).

local M = {}

M.config = {
  -- Стиль границ: 'ascii' | 'rounded' | 'single' | 'double' | 'github' | 'none'
  border = 'double',

  -- Внутренние вертикальные отступы строк ячеек (число строк: 0, 1, 2...)
  padding_top = 1,
  padding_bottom = 1,

  -- Отдельные отступы для шапки (nil - использовать padding_top/padding_bottom)
  header_padding_top = nil,
  header_padding_bottom = nil,

  -- Внешние отступы вокруг таблицы (пустые строки до и после таблицы)
  margin_top = 0,
  margin_bottom = 0,

  -- Минимальная комфортная ширина колонки с текстом
  min_wrapped_width = 16,
  min_wrapped_lines = 3,

  -- Потолок ширины таблицы (nil - по ширине окна/текстового столбца)
  max_width = nil,

  -- Преобразовывать теги <br> / <br/> внутри ячеек в перенос строки
  expand_br = true,

  -- Склеивать ли строки продолжения вида | | Описание | с предыдущей строкой
  merge_continuation_rows = false,
}

--------------------------------------------------------------------------------
-- Стили рамок
--------------------------------------------------------------------------------

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
  none = {
    top = nil,
    sep = { '  ', '   ', '  ' },
    bot = nil,
    vert = ' ',
    horiz = ' ',
  },
}

--------------------------------------------------------------------------------
-- Общие утилиты и UTF-8
--------------------------------------------------------------------------------

local function trim(str)
  return (str:gsub('^%s+', ''):gsub('%s+$', ''))
end

local width_cache = {}

local function vis_width(str)
  if not str or str == '' then
    return 0
  end
  local cached = width_cache[str]
  if cached then
    return cached
  end
  local width = vim.fn.strdisplaywidth(str)
  width_cache[str] = width
  return width
end

local function utf8_char_spans(str)
  local spans = {}
  local len = #str
  local i = 1
  while i <= len do
    local b = str:byte(i)
    local char_len = 1
    if b >= 240 then
      char_len = 4
    elseif b >= 224 then
      char_len = 3
    elseif b >= 192 then
      char_len = 2
    end
    local next_i = math.min(i + char_len, len + 1)
    spans[#spans + 1] = { i, next_i - 1 }
    i = next_i
  end
  return spans
end

--------------------------------------------------------------------------------
-- Очистка Markdown-разметки ячеек (чистый текст)
--------------------------------------------------------------------------------

local function clean_markdown_inlines(raw_text)
  local text = raw_text:gsub('\\|', '|')
  -- 1. Инлайн-код: `code` -> code
  text = text:gsub('`([^`]+)`', '%1')
  -- 2. Ссылки: [label](url) -> label
  text = text:gsub('%[([^%]]-)%]%([^%)]-%)', '%1')
  -- 3. Зачёркнутый: ~~text~~ -> text
  text = text:gsub('~~([^~]+)~~', '%1')
  -- 4. Звёздочки: ***text***, **text**, *text*
  text = text:gsub('%*%*%*([^*]+)%*%*%*', '%1')
  text = text:gsub('%*%*([^*]+)%*%*', '%1')
  text = text:gsub('%*([^*]+)%*', '%1')

  -- 5. Подчёркивания (___text___, __text__, _text_) ТОЛЬКО на границах слов/пробелах,
  -- чтобы не портить константы вида FIRST_SHOT_DATA и переменные snake_case
  local s = ' ' .. text .. ' '
  local changed = true
  while changed do
    local count = 0
    local c = 0
    s, c = s:gsub('([^%w])___([^_]+)___([^%w])', '%1%2%3')
    count = count + c
    if c == 0 then
      s, c = s:gsub('([^%w])__([^_]+)__([^%w])', '%1%2%3')
      count = count + c
    end
    if c == 0 then
      s, c = s:gsub('([^%w])_([^_]+)_([^%w])', '%1%2%3')
      count = count + c
    end
    changed = (count > 0)
  end

  return s:sub(2, -2)
end

--------------------------------------------------------------------------------
-- Разбор строк таблицы
--------------------------------------------------------------------------------

local function split_row(line)
  local cells = {}
  local from, escaped = nil, false
  for i = 1, #line do
    local char = line:sub(i, i)
    if escaped then
      escaped = false
    elseif char == '\\' then
      escaped = true
    elseif char == '|' then
      if from then
        cells[#cells + 1] = trim(line:sub(from, i - 1))
      end
      from = i + 1
    end
  end
  return cells
end

local function is_table_line(line)
  local t = trim(line)
  return #t > 1 and t:sub(1, 1) == '|' and t:sub(-1, -1) == '|'
end

local function is_separator_row(cells)
  if #cells == 0 then
    return false
  end
  for _, cell in ipairs(cells) do
    if
      not cell:match('^:[%-]+:$')
      and not cell:match('^:[%-]+$')
      and not cell:match('^[%-]+:$')
      and not cell:match('^[%-]+$')
    then
      return false
    end
  end
  return true
end

local function is_continuation_row(cells)
  if #cells == 0 then
    return false
  end
  return (cells[1] or '') == ''
end

--------------------------------------------------------------------------------
-- Токенизация и перенос слов
--------------------------------------------------------------------------------

local function tokenize_spans_simple(text)
  local spans = {}
  local i = 1
  local len = #text

  while i <= len do
    local _, ws_end = text:find('^%s+', i)
    if ws_end then
      i = ws_end + 1
    end
    if i > len then
      break
    end

    local token_start = i
    local ws_next = text:find('%s', i)
    local token_end = ws_next and (ws_next - 1) or len

    spans[#spans + 1] = { token_start, token_end }
    i = token_end + 1
  end

  return spans
end

local function wrap_spans(text, max_width)
  if max_width < 3 then
    max_width = 3
  end
  local raw_spans = tokenize_spans_simple(text)
  local atomic_spans = {}

  for _, span in ipairs(raw_spans) do
    local w = vis_width(text:sub(span[1], span[2]))
    if w <= max_width then
      atomic_spans[#atomic_spans + 1] = span
    else
      local word_str = text:sub(span[1], span[2])
      local chars = utf8_char_spans(word_str)
      local sub_start = span[1]
      local current_sub_w = 0

      for c_idx, ch in ipairs(chars) do
        local ch_w = vis_width(word_str:sub(ch[1], ch[2]))
        if current_sub_w + ch_w > max_width and current_sub_w > 0 then
          local prev_ch = chars[c_idx - 1]
          atomic_spans[#atomic_spans + 1] = { sub_start, span[1] + prev_ch[2] - 1 }
          sub_start = span[1] + ch[1] - 1
          current_sub_w = ch_w
        else
          current_sub_w = current_sub_w + ch_w
        end
      end
      if sub_start <= span[2] then
        atomic_spans[#atomic_spans + 1] = { sub_start, span[2] }
      end
    end
  end

  local lines = {}
  local current, current_w = {}, 0

  for _, span in ipairs(atomic_spans) do
    local w = vis_width(text:sub(span[1], span[2]))
    if #current == 0 then
      current, current_w = { span }, w
    elseif current_w + 1 + w <= max_width then
      current[#current + 1] = span
      current_w = current_w + 1 + w
    else
      lines[#lines + 1] = current
      current, current_w = { span }, w
    end
  end

  if #current > 0 then
    lines[#lines + 1] = current
  end
  if #lines == 0 then
    lines = { {} }
  end

  return lines
end

local function wrap_text(text, max_width)
  if vis_width(text) <= max_width then
    return { text }
  end
  local out = {}
  for _, line_spans in ipairs(wrap_spans(text, max_width)) do
    local parts = {}
    for _, span in ipairs(line_spans) do
      parts[#parts + 1] = text:sub(span[1], span[2])
    end
    out[#out + 1] = table.concat(parts, ' ')
  end
  return out
end

local function get_max_word_width(text)
  local max_w = 0
  for _, span in ipairs(tokenize_spans_simple(text)) do
    max_w = math.max(max_w, vis_width(text:sub(span[1], span[2])))
  end
  return max_w
end

--------------------------------------------------------------------------------
-- Расчёт ширин колонок
--------------------------------------------------------------------------------

local function read_alignments(separator_cells)
  local alignments = {}
  for col_idx, cell in ipairs(separator_cells) do
    local has_left = cell:sub(1, 1) == ':'
    local has_right = cell:sub(-1, -1) == ':'
    if has_left and has_right then
      alignments[col_idx] = 'center'
    elseif has_left then
      alignments[col_idx] = 'left'
    elseif has_right then
      alignments[col_idx] = 'right'
    else
      alignments[col_idx] = 'default'
    end
  end
  return alignments
end

local function calculate_target_widths(natural_widths, max_word_widths, available_width)
  local N = #natural_widths
  local total_natural = 0
  for i = 1, N do
    total_natural = total_natural + natural_widths[i]
  end

  if total_natural <= available_width then
    return vim.deepcopy(natural_widths)
  end

  local target_widths = {}
  local min_widths = {}
  local sum_min_widths = 0

  for i = 1, N do
    local min_w = math.max(math.min(max_word_widths[i] or 3, 20), 3)
    min_w = math.min(min_w, natural_widths[i])
    min_widths[i] = min_w
    sum_min_widths = sum_min_widths + min_w
  end

  if sum_min_widths >= available_width then
    local factor = available_width / math.max(sum_min_widths, 1)
    local allocated = 0
    for i = 1, N do
      target_widths[i] = math.max(math.floor(min_widths[i] * factor), 3)
      allocated = allocated + target_widths[i]
    end
    local rem = available_width - allocated
    local idx = 1
    while rem > 0 do
      target_widths[idx] = target_widths[idx] + 1
      rem = rem - 1
      idx = (idx % N) + 1
    end
    return target_widths
  end

  for i = 1, N do
    target_widths[i] = min_widths[i]
  end
  local remaining_width = available_width - sum_min_widths

  local total_remaining_natural = 0
  local active_indices = {}
  for i = 1, N do
    if natural_widths[i] > target_widths[i] then
      total_remaining_natural = total_remaining_natural + (natural_widths[i] - target_widths[i])
      table.insert(active_indices, i)
    end
  end

  if total_remaining_natural > 0 and remaining_width > 0 then
    local width_to_distribute = remaining_width
    for _, i in ipairs(active_indices) do
      local weight = (natural_widths[i] - target_widths[i]) / total_remaining_natural
      local added = math.floor(weight * width_to_distribute)
      target_widths[i] = target_widths[i] + added
      remaining_width = remaining_width - added
    end

    local idx = 1
    while remaining_width > 0 and #active_indices > 0 do
      local i = active_indices[idx]
      target_widths[i] = target_widths[i] + 1
      remaining_width = remaining_width - 1
      idx = (idx % #active_indices) + 1
    end
  end

  return target_widths
end

local function apply_comfort_widths(texts, max_cols, natural_widths, target_widths, available_width)
  if M.config.min_wrapped_width <= 0 then
    return
  end

  for col_idx = 1, max_cols do
    local width = target_widths[col_idx]
    if width < M.config.min_wrapped_width and (natural_widths[col_idx] or 0) > width then
      local height = 1
      for _, row in ipairs(texts) do
        height = math.max(height, #wrap_text(row[col_idx] or '', width))
      end

      if height >= M.config.min_wrapped_lines then
        local desired =
          math.max(width, math.min(natural_widths[col_idx], M.config.min_wrapped_width))
        local diff = desired - width

        local current_sum = 0
        for i = 1, max_cols do
          current_sum = current_sum + target_widths[i]
        end

        if current_sum + diff <= available_width then
          target_widths[col_idx] = desired
        end
      end
    end
  end
end

--------------------------------------------------------------------------------
-- Парсинг логических строк таблицы
--------------------------------------------------------------------------------

local function parse_logical_rows(buf, block)
  local lines = block.lines
  local sep_cells = split_row(lines[2] or '')
  if #lines < 2 or not is_separator_row(sep_cells) then
    return nil, nil, nil
  end

  local separator_idx = 2
  local alignments = read_alignments(sep_cells)

  local logical_rows = {}
  local cur_row = nil

  local function flush()
    if cur_row then
      logical_rows[#logical_rows + 1] = cur_row
      cur_row = nil
    end
  end

  for idx = 1, #lines do
    if idx == separator_idx then
      flush()
    else
      local row_num = block.start_line - 1 + idx - 1
      local raw_line = lines[idx]
      local splitted = split_row(raw_line)

      local parsed_cells = {}
      for col_idx, cell_text in ipairs(splitted) do
        parsed_cells[col_idx] = {
          text = clean_markdown_inlines(cell_text),
          raw = cell_text,
        }
      end

      local is_cont = M.config.merge_continuation_rows
        and (idx > separator_idx)
        and is_continuation_row(splitted)

      if is_cont and cur_row then
        cur_row.physical_rows[#cur_row.physical_rows + 1] = { row = row_num, len = #raw_line }
        local max_c = math.max(#cur_row.cells, #parsed_cells)
        for c = 1, max_c do
          local c1 = cur_row.cells[c]
          local c2 = parsed_cells[c]
          local t1 = c1 and c1.text or ''
          local t2 = c2 and c2.text or ''
          if t1 ~= '' and t2 ~= '' then
            cur_row.cells[c] = {
              text = t1 .. ' ' .. t2,
              raw = (c1.raw or '') .. ' ' .. (c2.raw or ''),
            }
          elseif t1 == '' and t2 ~= '' then
            cur_row.cells[c] = c2
          end
        end
      else
        flush()
        cur_row = {
          header = (idx < separator_idx),
          physical_rows = { { row = row_num, len = #raw_line } },
          cells = parsed_cells,
        }
      end
    end
  end
  flush()

  return logical_rows, alignments, separator_idx
end

--------------------------------------------------------------------------------
-- Отрисовка виртуальной таблицы
--------------------------------------------------------------------------------

local function find_table_blocks(lines)
  local blocks = {}
  local in_table = false
  local table_start = nil
  local table_lines = {}
  local fence = nil

  local function close_block(end_line)
    if in_table then
      table.insert(blocks, {
        start_line = table_start,
        end_line = end_line,
        lines = table_lines,
      })
      in_table = false
      table_lines = {}
    end
  end

  for i = 1, #lines do
    local trimmed = trim(lines[i])
    local fence_mark = trimmed:match('^(```+)') or trimmed:match('^(~~~+)')

    if fence then
      if fence_mark and fence_mark:sub(1, 1) == fence:sub(1, 1) and #fence_mark >= #fence then
        fence = nil
      end
    elseif fence_mark then
      close_block(i - 1)
      fence = fence_mark
    elseif is_table_line(lines[i]) then
      if not in_table then
        in_table = true
        table_start = i
        table_lines = {}
      end
      table.insert(table_lines, lines[i])
    else
      close_block(i - 1)
    end
  end

  close_block(#lines)
  return blocks
end

local function make_border_line(b_style, b_type, col_widths, indent)
  local def = b_style[b_type]
  if not def then
    return nil
  end
  local parts = {}
  for _, w in ipairs(col_widths) do
    parts[#parts + 1] = string.rep(b_style.horiz, w)
  end
  local line = def[1] .. table.concat(parts, def[2]) .. def[3]
  return { { indent .. line, 'MdTableBorder' } }
end

local function render_virtual_table(buf, block, total_width)
  local logical_rows, alignments, separator_idx = parse_logical_rows(buf, block)
  if not logical_rows or #logical_rows == 0 then
    return nil
  end

  local lines = block.lines
  local b_style = BORDER_STYLES[M.config.border] or BORDER_STYLES.ascii
  local indent = lines[1]:match('^(%s*)') or ''

  local max_cols = 0
  for _, row in ipairs(logical_rows) do
    max_cols = math.max(max_cols, #row.cells)
  end
  if max_cols == 0 then
    return nil
  end

  local indent_width = vim.fn.strdisplaywidth(indent)
  local available = total_width - indent_width - (3 * max_cols + 1)
  if available < max_cols * 3 then
    available = max_cols * 3
  end

  local natural_widths, max_word_widths = {}, {}
  local texts = {}
  for _, row in ipairs(logical_rows) do
    local row_texts = {}
    for col_idx = 1, max_cols do
      local cell = row.cells[col_idx]
      local raw = cell and cell.raw or ''
      local text = cell and cell.text or ''
      row_texts[col_idx] = text

      if M.config.expand_br and raw:find('<br%s*/?>') then
        local parts = vim.split(raw, '<br%s*/?>')
        for _, part in ipairs(parts) do
          local p_text = clean_markdown_inlines(trim(part))
          natural_widths[col_idx] = math.max(natural_widths[col_idx] or 3, vis_width(p_text))
          max_word_widths[col_idx] =
            math.max(max_word_widths[col_idx] or 0, get_max_word_width(p_text))
        end
      else
        natural_widths[col_idx] = math.max(natural_widths[col_idx] or 3, vis_width(text))
        max_word_widths[col_idx] = math.max(max_word_widths[col_idx] or 0, get_max_word_width(text))
      end
    end
    texts[#texts + 1] = row_texts
  end

  local target_widths = calculate_target_widths(natural_widths, max_word_widths, available)
  apply_comfort_widths(texts, max_cols, natural_widths, target_widths, available)

  local function put(str, width, align, out, default_hl)
    local content_w = vis_width(str)
    local padding = math.max(0, width - content_w)
    local left = 0
    if align == 'right' then
      left = padding
    elseif align == 'center' then
      left = math.floor(padding / 2)
    end
    local hl_def = default_hl or 'MdTableCell'
    if left > 0 then
      out[#out + 1] = { string.rep(' ', left), hl_def }
    end
    if str ~= '' then
      out[#out + 1] = { str, hl_def }
    end
    if padding - left > 0 then
      out[#out + 1] = { string.rep(' ', padding - left), hl_def }
    end
  end

  -- Отрисовка строки с непрерывной заливкой фона ячеек
  local function emit_row(get_cell_chunks, default_hl)
    local out = {}
    local hl_def = default_hl or 'MdTableCell'
    if indent ~= '' then
      out[#out + 1] = { indent, hl_def }
    end
    out[#out + 1] = { b_style.vert, 'MdTableBorder' }
    out[#out + 1] = { ' ', hl_def }
    for col_idx = 1, max_cols do
      if col_idx > 1 then
        out[#out + 1] = { ' ', hl_def }
        out[#out + 1] = { b_style.vert, 'MdTableBorder' }
        out[#out + 1] = { ' ', hl_def }
      end
      get_cell_chunks(col_idx, target_widths[col_idx], out)
    end
    out[#out + 1] = { ' ', hl_def }
    out[#out + 1] = { b_style.vert, 'MdTableBorder' }
    return out
  end

  local top_border = make_border_line(b_style, 'top', target_widths, indent)
  local sep_border = make_border_line(b_style, 'sep', target_widths, indent)
  local bot_border = make_border_line(b_style, 'bot', target_widths, indent)

  local out_physical = {}
  local data_row_idx = 0

  for _, row in ipairs(logical_rows) do
    local row_hl = 'MdTableCell'
    local is_head = row.header
    if is_head then
      row_hl = 'MdTableHead'
    else
      data_row_idx = data_row_idx + 1
      if data_row_idx % 2 == 1 then
        row_hl = 'MdTableCellOdd'
      else
        row_hl = 'MdTableCellEven'
      end
    end

    local wrapped, height = {}, 1
    for col_idx = 1, max_cols do
      local cell = row.cells[col_idx]
      local cell_lines = {}

      if cell then
        if M.config.expand_br and (cell.raw and cell.raw:find('<br%s*/?>')) then
          local raw_parts = vim.split(cell.raw, '<br%s*/?>')
          for _, part in ipairs(raw_parts) do
            local p_text = clean_markdown_inlines(trim(part))
            for _, w_line in ipairs(wrap_text(p_text, target_widths[col_idx])) do
              cell_lines[#cell_lines + 1] = w_line
            end
          end
        else
          cell_lines = wrap_text(cell.text, target_widths[col_idx])
        end
        wrapped[col_idx] = cell_lines
      else
        wrapped[col_idx] = {}
      end
      height = math.max(height, #wrapped[col_idx])
    end

    local rendered_lines = {}

    -- Внутренний отступ сверху (padding_top)
    local pad_top = is_head and (M.config.header_padding_top or M.config.padding_top or 0)
      or (M.config.padding_top or 0)
    for _ = 1, pad_top do
      rendered_lines[#rendered_lines + 1] = emit_row(function(col_idx, width, out)
        put('', width, 'default', out, row_hl)
      end, row_hl)
    end

    -- Текстовые строки ячейки
    for h = 1, height do
      rendered_lines[#rendered_lines + 1] = emit_row(function(col_idx, width, out)
        local text_line = (wrapped[col_idx] and wrapped[col_idx][h]) or ''
        put(text_line, width, alignments[col_idx] or 'default', out, row_hl)
      end, row_hl)
    end

    -- Внутренний отступ снизу (padding_bottom)
    local pad_bot = is_head and (M.config.header_padding_bottom or M.config.padding_bottom or 0)
      or (M.config.padding_bottom or 0)
    for _ = 1, pad_bot do
      rendered_lines[#rendered_lines + 1] = emit_row(function(col_idx, width, out)
        put('', width, 'default', out, row_hl)
      end, row_hl)
    end

    local num_phys = #row.physical_rows
    local num_rend = #rendered_lines

    if num_rend <= num_phys then
      for p = 1, num_phys do
        local phys = row.physical_rows[p]
        out_physical[#out_physical + 1] = {
          row = phys.row,
          len = phys.len,
          line = rendered_lines[p],
          virt_lines = nil,
          is_header = row.header,
          row_hl = row_hl,
        }
      end
    else
      for p = 1, num_phys do
        local phys = row.physical_rows[p]
        local rend_line = rendered_lines[p]
        local extra_virt = nil

        if p == num_phys then
          extra_virt = {}
          for r = num_phys + 1, num_rend do
            extra_virt[#extra_virt + 1] = rendered_lines[r]
          end
        end

        out_physical[#out_physical + 1] = {
          row = phys.row,
          len = phys.len,
          line = rend_line,
          virt_lines = extra_virt,
          is_header = row.header,
          row_hl = row_hl,
        }
      end
    end
  end

  local sep_row_num = block.start_line - 1 + separator_idx - 1
  local sep_line_rendered = nil
  if sep_border then
    sep_line_rendered = sep_border
  else
    sep_line_rendered = emit_row(function(col_idx, width, out)
      out[#out + 1] = { string.rep(b_style.horiz, width), 'MdTableBorder' }
    end, 'MdTableBorder')
  end

  local final_items = {}
  local sep_inserted = false

  for _, item in ipairs(out_physical) do
    if not sep_inserted and not item.is_header then
      final_items[#final_items + 1] = {
        row = sep_row_num,
        len = #lines[separator_idx],
        line = sep_line_rendered,
        virt_lines = nil,
        row_hl = 'MdTableBorder',
      }
      sep_inserted = true
    end
    final_items[#final_items + 1] = item
  end

  if not sep_inserted then
    final_items[#final_items + 1] = {
      row = sep_row_num,
      len = #lines[separator_idx],
      line = sep_line_rendered,
      virt_lines = nil,
      row_hl = 'MdTableBorder',
    }
  end

  if #final_items > 0 then
    final_items[1].top_border = top_border
    final_items[#final_items].bot_border = bot_border
  end

  return final_items
end

--------------------------------------------------------------------------------
-- Управление метками и отрисовка
--------------------------------------------------------------------------------

local ns = vim.api.nvim_create_namespace('md_table_render')
local cache = {}
local applied = {}
local decorated = {}

local function is_insert_mode()
  local mode = vim.api.nvim_get_mode().mode
  return mode:match('^[iRsS\19]') ~= nil
end

local function text_width(win)
  local info = vim.fn.getwininfo(win)[1]
  local win_w = info and info.width or vim.api.nvim_win_get_width(win)
  local textoff = info and (info.textoff or 0) or 0
  local available_cols = win_w - textoff - 4
  if M.config.max_width then
    available_cols = math.min(available_cols, M.config.max_width)
  end
  return math.max(available_cols, 20)
end

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
      blocks[#blocks + 1] = {
        first = block.start_line - 1,
        last = block.end_line - 1,
        rendered = rendered,
      }
    end
  end

  cache[buf] = { tick = tick, width = width, blocks = blocks }
  return blocks
end

local function ensure_window_conceal(win)
  if not vim.api.nvim_win_is_valid(win) then
    return
  end
  if vim.wo[win].conceallevel < 2 then
    vim.wo[win].conceallevel = 2
  end
  local cc = vim.wo[win].concealcursor
  if not cc:find('n') then
    vim.wo[win].concealcursor = (cc == '' and 'nc' or cc .. 'n')
  end
  if vim.wo[win].sidescrolloff ~= 0 then
    vim.wo[win].sidescrolloff = 0
  end
end

local function active(win, buf)
  if vim.b[buf].md_table_disable or vim.g.md_table_disable then
    return false
  end
  if vim.bo[buf].filetype ~= 'markdown' then
    return false
  end
  if is_insert_mode() and buf == vim.api.nvim_get_current_buf() then
    return false
  end
  ensure_window_conceal(win)
  return true
end

local function clear(buf)
  if vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  end
  applied[buf] = nil
end

local function refresh()
  local seen = {}

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if not seen[buf] and active(win, buf) then
      seen[buf] = true

      local width = text_width(win)
      local ok, blocks = pcall(buffer_blocks, buf, width)
      if not ok or not blocks then
        blocks = {}
      end

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
          -- Изолируем таблицу от md-conceal на строках таблицы
          local conceal_ns = vim.api.nvim_create_namespace('md_conceal')
          vim.api.nvim_buf_clear_namespace(buf, conceal_ns, block.first, block.last + 1)

          for _, item in ipairs(block.rendered) do
            local line_str = vim.api.nvim_buf_get_lines(buf, item.row, item.row + 1, false)[1] or ''
            local line_len = #line_str
            local row_hl = item.row_hl or 'MdTableCell'

            if item.line then
              -- Формируем чанки для строки
              local chunks_to_draw = {}
              local virt_w = 0
              for _, chunk in ipairs(item.line) do
                local text = chunk[1]
                local hl = chunk[2] or row_hl
                chunks_to_draw[#chunks_to_draw + 1] = { text, hl }
                virt_w = virt_w + vis_width(text)
              end

              -- Перекрываем остаток длины строки
              local pad = line_len - virt_w
              if pad > 0 then
                chunks_to_draw[#chunks_to_draw + 1] = { string.rep(' ', pad), row_hl }
              end

              -- Виртуальные строки переноса (screen line 1..N) и нижняя рамка
              local extra_virt_below = nil
              if (item.virt_lines and #item.virt_lines > 0) or item.bot_border then
                extra_virt_below = {}
                if item.virt_lines then
                  for _, vl in ipairs(item.virt_lines) do
                    extra_virt_below[#extra_virt_below + 1] = vl
                  end
                end
                if item.bot_border then
                  extra_virt_below[#extra_virt_below + 1] = item.bot_border
                  -- Внешний отступ снизу после таблицы (margin_bottom)
                  if M.config.margin_bottom and M.config.margin_bottom > 0 then
                    for _ = 1, M.config.margin_bottom do
                      extra_virt_below[#extra_virt_below + 1] = { { ' ', 'Normal' } }
                    end
                  end
                end
              end

              -- Верхняя рамка над первой строкой (+ внешний отступ margin_top)
              if item.top_border then
                local top_lines = {}
                if M.config.margin_top and M.config.margin_top > 0 then
                  for _ = 1, M.config.margin_top do
                    top_lines[#top_lines + 1] = { { ' ', 'Normal' } }
                  end
                end
                top_lines[#top_lines + 1] = item.top_border

                pcall(vim.api.nvim_buf_set_extmark, buf, ns, item.row, 0, {
                  virt_lines = top_lines,
                  virt_lines_above = true,
                  priority = 2000,
                })
              end

              -- Оверлей строки таблицы
              local extmark_opts = {
                end_row = item.row,
                end_col = line_len,
                conceal = '',
                virt_text = chunks_to_draw,
                virt_text_pos = 'overlay',
                hl_mode = 'replace',
                priority = 2000,
              }
              if extra_virt_below and #extra_virt_below > 0 then
                extmark_opts.virt_lines = extra_virt_below
                extmark_opts.virt_lines_above = false
              end

              pcall(vim.api.nvim_buf_set_extmark, buf, ns, item.row, 0, extmark_opts)
            else
              -- Схлопываем лишние физические строки продолжения буфера
              pcall(vim.api.nvim_buf_set_extmark, buf, ns, item.row, 0, {
                end_row = item.row,
                end_col = line_len,
                conceal = '',
                virt_text = { { string.rep(' ', math.max(line_len, 1)), 'MdTableCell' } },
                virt_text_pos = 'overlay',
                hl_mode = 'replace',
                priority = 2000,
              })
            end
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

vim.api.nvim_create_user_command('MdTableToggle', function()
  local buf = vim.api.nvim_get_current_buf()
  vim.b[buf].md_table_disable = not vim.b[buf].md_table_disable
  cache[buf] = nil
  clear(buf)
  schedule()
  vim.notify(
    vim.b[buf].md_table_disable and 'md-table: рендер выключен'
      or 'md-table: рендер включён',
    vim.log.levels.INFO
  )
end, { desc = 'Включить/выключить рендер таблиц' })

vim.api.nvim_create_user_command('MdTableRefresh', function()
  cache = {}
  applied = {}
  schedule()
end, { desc = 'Принудительно перерисовать таблицы' })

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
    cache[args.buf] = nil
    applied[args.buf] = nil
    decorated[args.buf] = nil
  end,
})

schedule()

return M
