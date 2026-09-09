-- Виртуальный рендерер markdown-таблиц (GitHub-style) для Neovim.
--
-- ОСОБЕННОСТИ:
--   * Все символы разметки (**, `, [], _) остаются видимыми без скрытия в документе.
--   * Полная поддержка wrap = true (визуальный перенос строк в окне).
--   * Полная защита от разрыва длинных строк таблицы терминалом (без паразитных строк и пробелов).
--   * Поддерживает центрирование (:--:) и выравнивание колонок.
--   * Корректно объединяет и выравнивает многострочные строки продолжения (| | |).
--   * В Insert/Replace режиме рендер отключается (чистый исходный Markdown).
--   * Сплошные рамки (ascii, rounded, single, double, github).

local M = {}

M.config = {
  -- Стиль границ: 'ascii' | 'rounded' | 'single' | 'double' | 'github' | 'none'
  border = 'ascii',

  -- Минимальная комфортная ширина колонки с текстом
  min_wrapped_width = 16,
  min_wrapped_lines = 3,

  -- Потолок ширины таблицы (nil - по ширине окна/текстового столбца)
  max_width = nil,

  -- Преобразовывать теги <br> / <br/> внутри ячеек в перенос строки
  expand_br = true,
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

local function disable_markdown_syntax_conceal()
  vim.g.markdown_syntax_conceal = 0
  for _, lang in ipairs({ 'markdown', 'markdown_inline' }) do
    pcall(function()
      local files = vim.treesitter.query.get_files(lang, 'highlights')
      if files and #files > 0 then
        local parts = {}
        for _, file in ipairs(files) do
          local f = io.open(file, 'r')
          if f then
            local content = f:read('*a')
            f:close()
            -- Удаляем правила скрытия символов разметки
            content = content:gsub('%(#[%w_]+!%s+conceal[^%)]*%)', '')
            parts[#parts + 1] = content
          end
        end
        if #parts > 0 then
          vim.treesitter.query.set(lang, 'highlights', table.concat(parts, '\n'))
        end
      end
    end)
  end
end

local function setup_highlights()
  vim.api.nvim_set_hl(0, 'MdTableBorder', { link = 'Comment', default = true })
  vim.api.nvim_set_hl(0, 'MdTableHead', { link = '@markup.strong', default = true })
  disable_markdown_syntax_conceal()
end

setup_highlights()

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
        cells[#cells + 1] = { text = trim(line:sub(from, i - 1)), from = from, to = i - 1 }
      end
      from = i + 1
    end
  end
  return cells
end

local function cell_texts(line)
  local out = {}
  for i, cell in ipairs(split_row(line)) do
    out[i] = cell.text
  end
  return out
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
  return trim(cells[1] or '') == ''
end

--------------------------------------------------------------------------------
-- Токенизация и безопасный перенос
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
-- Treesitter & Инлайн подсветка (без скрытия символов)
--------------------------------------------------------------------------------

local function line_marks(buf, row)
  local ok, parser = pcall(vim.treesitter.get_parser, buf, 'markdown', { error = false })
  if not ok or not parser then
    return nil
  end

  pcall(parser.parse, parser, { row, row + 1 })

  local hl = {}

  parser:for_each_tree(function(tree, ltree)
    local lang = ltree:lang()
    local query = vim.treesitter.query.get(lang, 'highlights')
    if not query then
      return
    end

    local root = tree:root()
    local root_start, _, root_end, _ = root:range()
    if row < root_start or row > root_end then
      return
    end

    for id, node, meta in query:iter_captures(root, buf, row, row + 1) do
      local sr, sc, er, ec = node:range()
      local entry = meta[id]
      local offset = entry and entry.offset
      if offset then
        sr = sr + tonumber(offset[1])
        sc = sc + tonumber(offset[2])
        er = er + tonumber(offset[3])
        ec = ec + tonumber(offset[4])
      end

      if sr <= row and er >= row then
        local from = (sr == row) and sc + 1 or 1
        local to = (er == row) and ec or math.huge

        local name = query.captures[id]
        local group = (name and name:sub(1, 1) ~= '_') and ('@' .. name) or nil

        if group then
          local line_str = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1] or ''
          local last = (to == math.huge) and #line_str or to
          for i = from, last do
            hl[i] = group
          end
        end
      end
    end
  end)

  return { hl = hl }
end

local function cell_chunks(line, marks, from, to)
  while from <= to and line:sub(from, from) == ' ' do
    from = from + 1
  end
  while to >= from and line:sub(to, to) == ' ' do
    to = to - 1
  end

  if to < from then
    return {}
  end

  local chunks = {}
  local run_start, run_hl = nil, nil

  local function flush(stop)
    if run_start and stop >= run_start then
      chunks[#chunks + 1] = { line:sub(run_start, stop), run_hl }
      run_start = nil
    end
  end

  local i = from
  while i <= to do
    local group = marks and marks.hl and marks.hl[i] or nil
    if not run_start then
      run_start, run_hl = i, group
    elseif group ~= run_hl then
      flush(i - 1)
      run_start, run_hl = i, group
    end
    i = i + 1
  end
  flush(to)

  return chunks
end

local function chunks_text(chunks)
  local parts, bounds, offset = {}, {}, 1
  for i, chunk in ipairs(chunks) do
    parts[i] = chunk[1]
    bounds[i] = { offset, offset + #chunk[1] - 1 }
    offset = offset + #chunk[1]
  end
  return table.concat(parts), bounds
end

local function slice_chunks(chunks, bounds, from, to, out)
  for i, chunk in ipairs(chunks) do
    local s, e = bounds[i][1], bounds[i][2]
    if e >= from and s <= to then
      local a = math.max(from, s) - s + 1
      local b = math.min(to, e) - s + 1
      local text = chunk[1]:sub(a, b)
      if text ~= '' then
        out[#out + 1] = { text, chunk[2] }
      end
    end
  end
end

--------------------------------------------------------------------------------
-- Парсинг логических строк
--------------------------------------------------------------------------------

local function parse_logical_rows(buf, block)
  local lines = block.lines
  if #lines < 2 or not is_separator_row(cell_texts(lines[2])) then
    return nil, nil, nil
  end

  local separator_idx = 2
  local alignments = read_alignments(cell_texts(lines[2]))

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
      local marks = line_marks(buf, row_num)
      local splitted = split_row(raw_line)

      local parsed_cells = {}
      for col_idx, cell in ipairs(splitted) do
        local chunks = cell_chunks(raw_line, marks, cell.from, cell.to)
        local text, bounds = chunks_text(chunks)
        parsed_cells[col_idx] = { chunks = chunks, bounds = bounds, text = text }
      end

      local raw_texts = cell_texts(raw_line)
      local is_cont = (idx > separator_idx) and is_continuation_row(raw_texts)

      if is_cont and cur_row then
        cur_row.physical_rows[#cur_row.physical_rows + 1] = { row = row_num, len = #raw_line }
        local max_c = math.max(#cur_row.cells, #parsed_cells)
        for c = 1, max_c do
          local c1 = cur_row.cells[c]
          local c2 = parsed_cells[c]
          local t1 = c1 and c1.text or ''
          local t2 = c2 and c2.text or ''
          if t1 ~= '' and t2 ~= '' then
            local comb_chunks = {}
            for _, ch in ipairs(c1.chunks) do
              comb_chunks[#comb_chunks + 1] = ch
            end
            comb_chunks[#comb_chunks + 1] = { ' ', nil }
            for _, ch in ipairs(c2.chunks) do
              comb_chunks[#comb_chunks + 1] = ch
            end
            local comb_text, comb_bounds = chunks_text(comb_chunks)
            cur_row.cells[c] = { chunks = comb_chunks, bounds = comb_bounds, text = comb_text }
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
  for i, w in ipairs(col_widths) do
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
      local text = row.cells[col_idx] and row.cells[col_idx].text or ''
      row_texts[col_idx] = text
      natural_widths[col_idx] = math.max(natural_widths[col_idx] or 3, vis_width(text))
      max_word_widths[col_idx] = math.max(max_word_widths[col_idx] or 0, get_max_word_width(text))
    end
    texts[#texts + 1] = row_texts
  end

  local target_widths = calculate_target_widths(natural_widths, max_word_widths, available)
  apply_comfort_widths(texts, max_cols, natural_widths, target_widths, available)

  local function put(chunks, width, align, out, head)
    local content_w = 0
    for _, chunk in ipairs(chunks) do
      content_w = content_w + vis_width(chunk[1])
    end
    local padding = math.max(0, width - content_w)
    local left = 0
    if align == 'right' then
      left = padding
    elseif align == 'center' then
      left = math.floor(padding / 2)
    end
    if left > 0 then
      out[#out + 1] = { string.rep(' ', left) }
    end
    for _, chunk in ipairs(chunks) do
      out[#out + 1] = { chunk[1], chunk[2] or (head and 'MdTableHead' or nil) }
    end
    if padding - left > 0 then
      out[#out + 1] = { string.rep(' ', padding - left) }
    end
  end

  local function emit_row(get_cell_chunks)
    local out = {}
    if indent ~= '' then
      out[#out + 1] = { indent }
    end
    out[#out + 1] = { b_style.vert .. ' ', 'MdTableBorder' }
    for col_idx = 1, max_cols do
      if col_idx > 1 then
        out[#out + 1] = { ' ' .. b_style.vert .. ' ', 'MdTableBorder' }
      end
      get_cell_chunks(col_idx, target_widths[col_idx], out)
    end
    out[#out + 1] = { ' ' .. b_style.vert, 'MdTableBorder' }
    return out
  end

  local top_border = make_border_line(b_style, 'top', target_widths, indent)
  local sep_border = make_border_line(b_style, 'sep', target_widths, indent)
  local bot_border = make_border_line(b_style, 'bot', target_widths, indent)

  local out_physical = {}

  -- Рендерим логические строки
  for _, row in ipairs(logical_rows) do
    local wrapped, height = {}, 1
    for col_idx = 1, max_cols do
      local cell = row.cells[col_idx]
      if cell then
        local cell_lines = {}
        if M.config.expand_br and cell.text:find('<br%s*/?>') then
          local raw_parts = vim.split(cell.text, '<br%s*/?>')
          for _, part in ipairs(raw_parts) do
            local p_wrapped = wrap_spans(part, target_widths[col_idx])
            for _, w_line in ipairs(p_wrapped) do
              cell_lines[#cell_lines + 1] = w_line
            end
          end
        else
          cell_lines = wrap_spans(cell.text, target_widths[col_idx])
        end
        wrapped[col_idx] = cell_lines
      else
        wrapped[col_idx] = { {} }
      end
      height = math.max(height, #wrapped[col_idx])
    end

    local rendered_lines = {}
    for h = 1, height do
      rendered_lines[#rendered_lines + 1] = emit_row(function(col_idx, width, out)
        local cell = row.cells[col_idx]
        local line_spans = wrapped[col_idx][h]
        local chunks = {}
        if cell and line_spans then
          for i, span in ipairs(line_spans) do
            if i > 1 then
              chunks[#chunks + 1] = { ' ', nil }
            end
            slice_chunks(cell.chunks, cell.bounds, span[1], span[2], chunks)
          end
        end
        put(chunks, width, alignments[col_idx] or 'default', out, row.header)
      end)
    end

    -- Распределяем строки по физическим строкам буфера
    local num_phys = #row.physical_rows
    local num_rend = #rendered_lines

    if num_rend <= num_phys then
      for p = 1, num_phys do
        local phys = row.physical_rows[p]
        if p <= num_rend then
          out_physical[#out_physical + 1] = {
            row = phys.row,
            len = phys.len,
            line = rendered_lines[p],
            virt_lines = nil,
            is_header = row.header,
          }
        else
          -- Лишние физические строки буфера полностью скрываем (0 высоты)
          out_physical[#out_physical + 1] = {
            row = phys.row,
            len = phys.len,
            line = nil,
            virt_lines = nil,
            is_header = row.header,
          }
        end
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
        }
      end
    end
  end

  -- Подготавливаем разделитель таблицы
  local sep_row_num = block.start_line - 1 + separator_idx - 1
  local sep_line_rendered = nil
  if sep_border then
    sep_line_rendered = sep_border
  else
    sep_line_rendered = {
      emit_row(function(col_idx, width, out)
        out[#out + 1] = { string.rep(b_style.horiz, width), 'MdTableBorder' }
      end),
    }
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
      }, ':')

      if applied[buf] ~= key then
        vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

        for _, block in ipairs(blocks) do
          for _, item in ipairs(block.rendered) do
            local line_str = vim.api.nvim_buf_get_lines(buf, item.row, item.row + 1, false)[1] or ''
            local line_len = #line_str

            -- Мы выводим ВСЕ виртуальные строки таблицы через virt_lines_above.
            -- Это на 100% поддерживается в любых версиях Neovim (начиная с 0.6)
            -- и гарантированно не конфликтует с API и опцией wrap.
            local all_lines_to_draw = {}
            if item.top_border then
              all_lines_to_draw[#all_lines_to_draw + 1] = item.top_border
            end
            if item.line then
              all_lines_to_draw[#all_lines_to_draw + 1] = item.line
            end
            if item.virt_lines and #item.virt_lines > 0 then
              for _, vl in ipairs(item.virt_lines) do
                all_lines_to_draw[#all_lines_to_draw + 1] = vl
              end
            end
            if item.bot_border then
              all_lines_to_draw[#all_lines_to_draw + 1] = item.bot_border
            end

            if #all_lines_to_draw > 0 then
              pcall(vim.api.nvim_buf_set_extmark, buf, ns, item.row, 0, {
                end_row = item.row,
                end_col = line_len,
                conceal = '',
                virt_lines = all_lines_to_draw,
                virt_lines_above = true,
                priority = 1000,
              })
            else
              -- Лишняя физическая строка полностью скрывается через conceal (0 высоты)
              pcall(vim.api.nvim_buf_set_extmark, buf, ns, item.row, 0, {
                end_row = item.row,
                end_col = line_len,
                conceal = '',
                priority = 1000,
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
  setup_highlights()
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
