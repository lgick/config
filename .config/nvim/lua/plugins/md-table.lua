-- Виртуальный рендерер markdown-таблиц (GitHub-style) для Neovim.
--
-- ОСОБЕННОСТИ:
--   * Файл остаётся каноническим GFM (одна физическая строка = одна строка таблицы).
--   * В Normal/Visual режимах таблица ВСЕГДА остаётся собранной и красивой под курсором.
--   * Блок таблицы раскрывается в сырой вид ТОЛЬКО при переходе в Insert/Replace режим.
--   * Защита от терминального переноса: расчёт ширины с учётом textoff (номера строк/знаки).
--   * Полная поддержка gj/gk и плавного перемещения курсора без зависаний.
--   * Полная совместимость с wrap = true и авто-форматированием Prettier.
--   * Сплошные бесшовные рамки (rounded, single, github, double, ascii), <br> и чекбоксы.

local M = {}

M.config = {
  -- Стиль границ: 'rounded' | 'single' | 'double' | 'github' | 'ascii' | 'none'
  border = 'ascii',

  -- Минимальная комфортная ширина колонки с текстом
  min_wrapped_width = 16,
  min_wrapped_lines = 3,

  -- Потолок ширины таблицы (nil - по ширине окна/текстового столбца)
  max_width = nil,

  -- Автоматически выставлять conceallevel = 2, concealcursor = 'nc' и sidescrolloff = 0
  setup_conceal = true,

  -- Преобразовывать теги <br> / <br/> внутри ячеек в перенос строки (как на GitHub)
  expand_br = true,

  -- Отображать чекбоксы [ ] и [x] иконками
  render_checkboxes = true,
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

local LEGACY_RULE_CHAR = '~'
local LEGACY_RULE_PATTERN = '^' .. vim.pesc(LEGACY_RULE_CHAR) .. '+$'

local function setup_highlights()
  vim.api.nvim_set_hl(0, 'MdTableBorder', { link = 'Comment', default = true })
  vim.api.nvim_set_hl(0, 'MdTableHead', { link = '@markup.strong', default = true })
  vim.api.nvim_set_hl(0, 'MdTableCheckOk', { link = 'DiagnosticOk', default = true })
  vim.api.nvim_set_hl(0, 'MdTableCheckNo', { link = 'Comment', default = true })
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

local function raw_width(str)
  local _, escaped = str:gsub('\\|', '')
  return vim.fn.strdisplaywidth(str) - escaped
end

local function lines_equal(a, b)
  if #a ~= #b then
    return false
  end
  for i = 1, #a do
    if a[i] ~= b[i] then
      return false
    end
  end
  return true
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

local function is_rule_row(cells)
  if #cells == 0 then
    return false
  end
  for _, cell in ipairs(cells) do
    if #cell < 3 or not cell:match(LEGACY_RULE_PATTERN) then
      return false
    end
  end
  return true
end

local function is_continuation_row(cells)
  return (cells[1] or '') == ''
end

local function merge_cells(into, cells)
  for col_idx = 1, math.max(#into, #cells) do
    local val1 = into[col_idx] or ''
    local val2 = cells[col_idx] or ''
    if val1 ~= '' and val2 ~= '' then
      into[col_idx] = val1 .. ' ' .. val2
    elseif val1 == '' then
      into[col_idx] = val2
    end
  end
  return into
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
-- Treesitter & Инлайн стилизация
--------------------------------------------------------------------------------

local function line_marks(buf, row)
  local ok, parser = pcall(vim.treesitter.get_parser, buf, 'markdown', { error = false })
  if not ok or not parser then
    return nil
  end

  pcall(parser.parse, parser, { row, row + 1 })

  local hl, hidden, replace = {}, {}, {}

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

        local conceal = meta.conceal
        if conceal == nil and entry then
          conceal = entry.conceal
        end

        local name = query.captures[id]
        local group = (name and name:sub(1, 1) ~= '_') and ('@' .. name) or nil

        if conceal ~= nil and sr == row and er == row and to >= from then
          replace[from] = conceal ~= '' and conceal or nil
          for i = from, to do
            hidden[i] = true
          end
        elseif group then
          local line_str = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1] or ''
          local last = (to == math.huge) and #line_str or to
          for i = from, last do
            hl[i] = group
          end
        end
      end
    end
  end)

  return { hl = hl, hidden = hidden, replace = replace }
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
    if line:sub(i, i) == '\\' and line:sub(i + 1, i + 1) == '|' then
      flush(i - 1)
      chunks[#chunks + 1] = { '|', nil }
      i = i + 2
      run_start = i
    elseif marks and marks.hidden[i] then
      flush(i - 1)
      local rep = marks.replace[i]
      if rep then
        chunks[#chunks + 1] = { rep, marks.hl[i] }
      end
      i = i + 1
      run_start = i
    else
      local group = marks and marks.hl[i] or nil
      if not run_start then
        run_start, run_hl = i, group
      elseif group ~= run_hl then
        flush(i - 1)
        run_start, run_hl = i, group
      end
      i = i + 1
    end
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

local function process_cell_enhancements(chunks)
  local result = {}
  for _, chunk in ipairs(chunks) do
    local text, hl = chunk[1], chunk[2]
    if M.config.render_checkboxes then
      if text:find('^%[%s%]') then
        text = text:gsub('^%[%s%]', '☐')
        hl = 'MdTableCheckNo'
      elseif text:find('^%[[xX]%]') then
        text = text:gsub('^%[[xX]%]', '☑')
        hl = 'MdTableCheckOk'
      end
    end
    result[#result + 1] = { text, hl }
  end
  return result
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
  local lines = block.lines
  if #lines < 2 or not is_separator_row(cell_texts(lines[2])) then
    return nil
  end

  local b_style = BORDER_STYLES[M.config.border] or BORDER_STYLES.rounded
  local separator_row = 2
  local alignments = read_alignments(cell_texts(lines[2]))
  local indent = lines[1]:match('^(%s*)') or ''

  local rows = {}
  local max_cols = 0
  for idx, line in ipairs(lines) do
    if idx ~= separator_row then
      local row_num = block.start_line - 1 + idx - 1
      local marks = line_marks(buf, row_num)
      local cells = {}
      for col_idx, cell in ipairs(split_row(line)) do
        local raw_chunks = cell_chunks(line, marks, cell.from, cell.to)
        local chunks = process_cell_enhancements(raw_chunks)
        local text, bounds = chunks_text(chunks)
        cells[col_idx] = { chunks = chunks, bounds = bounds, text = text }
      end
      max_cols = math.max(max_cols, #cells)
      rows[#rows + 1] = { cells = cells, header = (idx == 1) }
    end
  end

  if max_cols == 0 then
    return nil
  end

  local indent_width = vim.fn.strdisplaywidth(indent)
  local available = total_width - indent_width - (3 * max_cols) - 1
  if available < max_cols * 3 then
    available = max_cols * 3
  end

  local natural_widths, max_word_widths = {}, {}
  local texts = {}
  for _, row in ipairs(rows) do
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

  local sink = nil
  local vert = b_style.vert

  local function emit(get_cell_chunks)
    local out = {}
    if indent ~= '' then
      out[#out + 1] = { indent }
    end
    out[#out + 1] = { vert .. ' ', 'MdTableBorder' }
    for col_idx = 1, max_cols do
      if col_idx > 1 then
        out[#out + 1] = { ' ' .. vert .. ' ', 'MdTableBorder' }
      end
      get_cell_chunks(col_idx, target_widths[col_idx], out)
    end
    out[#out + 1] = { ' ' .. vert, 'MdTableBorder' }
    sink[#sink + 1] = out
  end

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

  local out_rows = {}
  local data_idx = 0
  local top_border = make_border_line(b_style, 'top', target_widths, indent)
  local sep_border = make_border_line(b_style, 'sep', target_widths, indent)
  local bot_border = make_border_line(b_style, 'bot', target_widths, indent)

  for idx = 1, #lines do
    sink = {}

    if idx == separator_row then
      if sep_border then
        sink[1] = sep_border
      else
        emit(function(col_idx, width, out)
          out[#out + 1] = { string.rep(b_style.horiz, width), 'MdTableBorder' }
        end)
      end
    else
      data_idx = data_idx + 1
      local row = rows[data_idx]

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

      for h = 1, height do
        emit(function(col_idx, width, out)
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
    end

    out_rows[#out_rows + 1] = {
      row = block.start_line - 1 + idx - 1,
      len = #lines[idx],
      lines = sink,
      top_border = (idx == 1) and top_border or nil,
      bot_border = (idx == #lines) and bot_border or nil,
    }
  end

  return out_rows
end

--------------------------------------------------------------------------------
-- Управление метками и отрисовка
--------------------------------------------------------------------------------

local ns = vim.api.nvim_create_namespace('md_table_render')
local cache = {}
local applied = {}
local decorated = {}

local function text_width(win)
  local info = vim.fn.getwininfo(win)[1]
  local win_w = info and info.width or vim.api.nvim_win_get_width(win)
  local textoff = info and (info.textoff or 0) or 0
  -- Чистая ширина доступного текста за вычетом всех колонок отступов/номеров строк
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
  if not M.config.setup_conceal then
    return
  end
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
  ensure_window_conceal(win)
  if vim.wo[win].conceallevel == 0 then
    return false
  end
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
      if not ok then
        blocks = {}
      end

      local editing = nil
      local mode = vim.api.nvim_get_mode().mode
      local is_insert = mode == 'i' or mode == 'R' or mode == 'ic' or mode == 'ix'

      local cur_win = vim.api.nvim_get_current_win()
      if cur_win == win then
        local cur = vim.api.nvim_win_get_cursor(win)
        local cursor_row = cur[1] - 1

        for idx, block in ipairs(blocks) do
          if cursor_row >= block.first and cursor_row <= block.last then
            if is_insert then
              editing = idx
            end
            break
          end
        end
      end

      local key = table.concat({
        vim.api.nvim_buf_get_changedtick(buf),
        width,
        tostring(editing),
        M.config.border,
      }, ':')

      if applied[buf] ~= key then
        vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

        for idx, block in ipairs(blocks) do
          if idx ~= editing then
            for _, row in ipairs(block.rendered) do
              local rest = {}
              if #row.lines > 1 then
                for l_idx = 2, #row.lines do
                  rest[#rest + 1] = row.lines[l_idx]
                end
              end

              if row.bot_border then
                rest[#rest + 1] = row.bot_border
              end

              if row.top_border then
                pcall(vim.api.nvim_buf_set_extmark, buf, ns, row.row, 0, {
                  virt_lines = { row.top_border },
                  virt_lines_above = true,
                  priority = 1000,
                })
              end

              -- Строка буфера заменяется первой строкой через overlay без пустых строк переноса
              pcall(vim.api.nvim_buf_set_extmark, buf, ns, row.row, 0, {
                end_row = row.row,
                end_col = row.len,
                conceal = '',
                virt_text = row.lines[1],
                virt_text_pos = 'overlay',
                virt_lines = #rest > 0 and rest or nil,
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
-- :MdTableNormalize - Нормализация таблиц к GFM
--------------------------------------------------------------------------------

local function render_flat(indent, parsed_rows, separator_idx)
  local alignments = read_alignments(parsed_rows[separator_idx])
  local max_cols = 0
  for _, cells in ipairs(parsed_rows) do
    max_cols = math.max(max_cols, #cells)
  end

  local widths = {}
  for row_idx, cells in ipairs(parsed_rows) do
    if row_idx ~= separator_idx then
      for col_idx = 1, max_cols do
        widths[col_idx] = math.max(widths[col_idx] or 3, raw_width(cells[col_idx] or ''))
      end
    end
  end
  for col_idx = 1, max_cols do
    widths[col_idx] = math.max(widths[col_idx] or 3, 3)
  end

  local out = {}
  for row_idx, cells in ipairs(parsed_rows) do
    local formatted = {}
    for col_idx = 1, max_cols do
      if row_idx == separator_idx then
        local align = alignments[col_idx] or 'default'
        local w = widths[col_idx]
        if align == 'center' then
          formatted[col_idx] = ':' .. string.rep('-', w - 2) .. ':'
        elseif align == 'left' then
          formatted[col_idx] = ':' .. string.rep('-', w - 1)
        elseif align == 'right' then
          formatted[col_idx] = string.rep('-', w - 1) .. ':'
        else
          formatted[col_idx] = string.rep('-', w)
        end
      else
        local cell = cells[col_idx] or ''
        local padding = widths[col_idx] - raw_width(cell)
        local align = alignments[col_idx] or 'default'
        if padding <= 0 then
          formatted[col_idx] = cell
        elseif align == 'right' then
          formatted[col_idx] = string.rep(' ', padding) .. cell
        elseif align == 'center' then
          local left = math.floor(padding / 2)
          formatted[col_idx] = string.rep(' ', left) .. cell .. string.rep(' ', padding - left)
        else
          formatted[col_idx] = cell .. string.rep(' ', padding)
        end
      end
    end
    out[#out + 1] = indent .. '| ' .. table.concat(formatted, ' | ') .. ' |'
  end

  return out
end

local function parse_table_lines(table_lines)
  local all_rows = {}
  for _, line in ipairs(table_lines) do
    table.insert(all_rows, cell_texts(trim(line)))
  end

  local delimiter_idx = nil
  for idx, cells in ipairs(all_rows) do
    if is_separator_row(cells) then
      delimiter_idx = idx
      break
    end
  end

  if not delimiter_idx then
    return nil, nil
  end

  local parsed_rows = {}
  local header = nil
  for i = 1, delimiter_idx - 1 do
    if not header then
      header = vim.deepcopy(all_rows[i])
    else
      merge_cells(header, all_rows[i])
    end
  end
  if header then
    table.insert(parsed_rows, header)
  end

  table.insert(parsed_rows, all_rows[delimiter_idx])
  local new_delimiter_idx = #parsed_rows

  local current_logical_row = nil
  local function flush()
    if current_logical_row then
      table.insert(parsed_rows, current_logical_row)
      current_logical_row = nil
    end
  end

  for i = delimiter_idx + 1, #all_rows do
    local cells = all_rows[i]
    if is_separator_row(cells) or is_rule_row(cells) then
      flush()
    elseif current_logical_row and is_continuation_row(cells) then
      merge_cells(current_logical_row, cells)
    else
      flush()
      current_logical_row = vim.deepcopy(cells)
    end
  end

  flush()
  return parsed_rows, new_delimiter_idx
end

local function normalize_buffer(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(bufnr) or not vim.bo[bufnr].modifiable then
    return 0
  end

  local blocks = find_table_blocks(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false))
  local fixed = 0

  for i = #blocks, 1, -1 do
    local block = blocks[i]
    local indent = block.lines[1]:match('^(%s*)') or ''
    local parsed_rows, separator_idx = parse_table_lines(block.lines)
    if parsed_rows then
      local flat = render_flat(indent, parsed_rows, separator_idx)
      if not lines_equal(flat, block.lines) then
        vim.api.nvim_buf_set_lines(bufnr, block.start_line - 1, block.end_line, false, flat)
        fixed = fixed + 1
      end
    end
  end

  return fixed
end

--------------------------------------------------------------------------------
-- Инициализация и автокоманды
--------------------------------------------------------------------------------

function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})
  setup_highlights()
  schedule()
end

vim.api.nvim_create_user_command('MdTableNormalize', function()
  local fixed = normalize_buffer(0)
  vim.notify(
    fixed > 0 and ('Приведено к каноническому GFM таблиц: ' .. fixed)
      or 'Таблицы уже канонические',
    vim.log.levels.INFO
  )
end, {
  desc = 'Склеить перенесённые ячейки и нормализовать GFM таблицы',
})

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

vim.api.nvim_create_autocmd('OptionSet', {
  group = group,
  pattern = { 'conceallevel', 'concealcursor' },
  callback = schedule,
})

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
