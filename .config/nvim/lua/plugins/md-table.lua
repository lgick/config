-- Таблица конфигурации
local config = {
  -- Если true, спецсимволы разметки (**, `, *, ~~, ссылки) НЕ учитываются при расчете ширины.
  -- Держим false: в файле таблица выравнивается по "сырой" ширине, как её видят
  -- prettier, git diff и GitHub. Компенсацию скрытых (conceal) символов на экране
  -- берёт на себя render-markdown с pipe_table.cell = 'padded'.
  ignore_markdown_syntax = false,

  -- Максимальная ширина таблицы (совпадает с printWidth: 80 у prettier).
  max_width = 80,

  -- Если true, между логическими строками рисуется разделитель |---|---|
  -- (стиль "grid"). Граница логической строки однозначна, но GFM-парсер
  -- считает такой разделитель началом новой таблицы: render-markdown рисует
  -- лишние границы, а последняя строка переноса подсвечивается как шапка.
  -- Лечится pipe_table.style = 'normal' в render-markdown.lua.
  -- Если false, перенос обозначается пустой первой ячейкой: валидный GFM и
  -- чистая отрисовка, но строка с реально пустой первой колонкой приклеится
  -- к предыдущей.
  row_separators = true,
}

local table_format_group = vim.api.nvim_create_augroup('MarkdownTableAutoFormat', { clear = true })

-- Токенизатор текста, защищающий специальные выражения от разбиения
local function tokenize_text(text)
  local tokens = {}
  local i = 1
  local len = #text

  while i <= len do
    -- Пропускаем начальные пробелы
    local space_start, space_end = text:find('^%s+', i)
    if space_start then
      i = space_end + 1
    end

    if i > len then
      break
    end

    -- Ссылка / картинка: [текст](url) и ![текст](url) - могут содержать
    -- пробелы, но разрывать их нельзя, иначе ссылка перестанет работать
    local link_end = select(2, text:find('^!?%[[^%]]-%]%([^%)]-%)', i))
    -- HTML-тег: <img src="..." alt="..."> - тоже с пробелами внутри
    local tag_end = not link_end and select(2, text:find('^<[^<>]->', i)) or nil

    if link_end then
      table.insert(tokens, text:sub(i, link_end))
      i = link_end + 1
    elseif tag_end then
      table.insert(tokens, text:sub(i, tag_end))
      i = tag_end + 1
    -- Проверка на жирный шрифт: **
    elseif text:sub(i, i + 1) == '**' then
      local next_bold = text:find('%*%*', i + 2)
      if next_bold then
        local token = text:sub(i, next_bold + 1)
        table.insert(tokens, token)
        i = next_bold + 2
      else
        local token_end = text:find('%s', i) or (len + 1)
        table.insert(tokens, text:sub(i, token_end - 1))
        i = token_end
      end
    -- Проверка на встроенный код (backticks): `
    elseif text:sub(i, i) == '`' then
      local next_backtick = text:find('`', i + 1)
      if next_backtick then
        local token = text:sub(i, next_backtick)
        table.insert(tokens, token)
        i = next_backtick + 1
      else
        local token_end = text:find('%s', i) or (len + 1)
        table.insert(tokens, text:sub(i, token_end - 1))
        i = token_end
      end
    else
      -- Обычное слово до следующего пробела, обратной кавычки или **
      local next_space = text:find('%s', i) or (len + 1)
      local next_backtick = text:find('`', i) or (len + 1)
      local next_bold = text:find('%*%*', i) or (len + 1)
      local next_link = text:find('!?%[[^%]]-%]%([^%)]-%)', i) or (len + 1)
      local next_tag = text:find('<[^<>]->', i) or (len + 1)
      local token_end =
        math.min(next_space, next_backtick, next_bold, next_link, next_tag)

      if token_end > i then
        local token = text:sub(i, token_end - 1)
        table.insert(tokens, token)
        i = token_end
      end
    end
  end

  return tokens
end

-- Вспомогательная функция очистки разметки (теперь на базе безопасных токенов)
local function strip_markdown_syntax(str)
  -- 1. Сначала убираем ссылки и картинки (они могут содержать пробелы)
  str = str:gsub('!%[([^%]]-)%]%([^%)]-%)', '%1')
  str = str:gsub('%[([^%]]-)%]%([^%)]-%)', '%1')

  -- 2. Разбиваем на токены для безопасной очистки без повреждения путей/глобов
  local tokens = tokenize_text(str)
  local stripped_tokens = {}

  for _, token in ipairs(tokens) do
    local stripped = token
    -- Если это инлайн-код (backticks), убираем только сами кавычки, внутренности не трогаем!
    if token:sub(1, 1) == '`' and token:sub(-1, -1) == '`' then
      stripped = token:sub(2, -2)
    -- Для жирного текста, курсива и зачеркиваний очищаем рекурсивно внешние маркеры
    elseif token:sub(1, 2) == '**' and token:sub(-2, -1) == '**' then
      stripped = strip_markdown_syntax(token:sub(3, -3))
    elseif token:sub(1, 2) == '__' and token:sub(-2, -1) == '__' then
      stripped = strip_markdown_syntax(token:sub(3, -3))
    elseif token:sub(1, 2) == '~~' and token:sub(-2, -1) == '~~' then
      stripped = strip_markdown_syntax(token:sub(3, -3))
    elseif token:sub(1, 1) == '*' and token:sub(-1, -1) == '*' and #token > 2 then
      stripped = strip_markdown_syntax(token:sub(2, -2))
    elseif token:sub(1, 1) == '_' and token:sub(-1, -1) == '_' and #token > 2 then
      stripped = strip_markdown_syntax(token:sub(2, -2))
    end
    table.insert(stripped_tokens, stripped)
  end

  return table.concat(stripped_tokens, ' ')
end

-- Разделение строки по '|' с учетом экранирования
local function split_row(line)
  local cells = {}
  local current = ''
  local escaped = false
  for i = 1, #line do
    local char = line:sub(i, i)
    if escaped then
      current = current .. char
      escaped = false
    elseif char == '\\' then
      current = current .. char
      escaped = true
    elseif char == '|' then
      table.insert(cells, current)
      current = ''
    else
      current = current .. char
    end
  end
  table.insert(cells, current)

  if #cells > 1 then
    table.remove(cells, 1)
  end
  if #cells > 0 then
    table.remove(cells)
  end

  for idx, cell in ipairs(cells) do
    cells[idx] = cell:gsub('^%s+', ''):gsub('%s+$', '')
  end

  return cells
end

-- Проверка на строку-разделитель (типа |---|)
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

-- Проверка на строку-продолжение (перенос предыдущей логической строки):
-- первая колонка пустая
local function is_continuation_row(cells)
  return (cells[1] or '') == ''
end

-- Умный парсинг табличных строк с обратным склеиванием перенесенных ячеек
local function parse_table_lines(table_lines)
  local all_rows = {}
  for _, line in ipairs(table_lines) do
    local trimmed_line = line:gsub('^%s+', ''):gsub('%s+$', '')
    table.insert(all_rows, split_row(trimmed_line))
  end

  -- Находим первый разделитель - он отделяет шапку от данных
  local delimiter_idx = nil
  local sep_count = 0
  for idx, cells in ipairs(all_rows) do
    if is_separator_row(cells) then
      sep_count = sep_count + 1
      if not delimiter_idx then
        delimiter_idx = idx
      end
    end
  end

  -- Больше одного разделителя - таблица уже в стиле grid: границы логических
  -- строк заданы разделителями, и первая колонка тоже могла быть перенесена,
  -- поэтому эвристика "пустая первая ячейка" здесь не применима
  local grid_style = sep_count > 1

  if not delimiter_idx then
    delimiter_idx = math.min(2, #all_rows)
  end

  local parsed_rows = {}
  -- Шапка в GFM - ровно одна строка (разделитель обязан быть второй строкой
  -- таблицы). Всё, что стоит до разделителя, склеиваем в одну логическую строку:
  -- это же чинит файлы, где шапку уже успело разорвать на несколько строк
  local header = nil
  for i = 1, delimiter_idx - 1 do
    local cells = all_rows[i]
    if not header then
      header = vim.deepcopy(cells)
    else
      for col_idx = 1, math.max(#header, #cells) do
        local val1 = header[col_idx] or ''
        local val2 = cells[col_idx] or ''
        if val1 ~= '' and val2 ~= '' then
          header[col_idx] = val1 .. ' ' .. val2
        elseif val1 == '' then
          header[col_idx] = val2
        end
      end
    end
  end
  if header then
    table.insert(parsed_rows, header)
  end

  -- Переносим главный разделитель
  if all_rows[delimiter_idx] then
    table.insert(parsed_rows, all_rows[delimiter_idx])
  end
  local new_delimiter_idx = #parsed_rows

  -- Склеиваем строки данных обратно перед новым форматированием.
  -- Логическая строка закрывается разделителем (стиль grid) либо началом
  -- строки с непустой первой колонкой (стиль с пустой первой ячейкой).
  local current_logical_row = nil

  local function flush()
    if current_logical_row then
      table.insert(parsed_rows, current_logical_row)
      current_logical_row = nil
    end
  end

  local function merge(cells)
    local max_c = math.max(#current_logical_row, #cells)
    for col_idx = 1, max_c do
      local val1 = current_logical_row[col_idx] or ''
      local val2 = cells[col_idx] or ''
      if val1 ~= '' and val2 ~= '' then
        current_logical_row[col_idx] = val1 .. ' ' .. val2
      elseif val1 == '' then
        current_logical_row[col_idx] = val2
      end
    end
  end

  for i = delimiter_idx + 1, #all_rows do
    local cells = all_rows[i]
    if is_separator_row(cells) then
      -- Промежуточный разделитель, добавленный самим форматтером: он лишь
      -- закрывает логическую строку и заново вставляется при форматировании
      flush()
    elseif current_logical_row and (grid_style or is_continuation_row(cells)) then
      merge(cells)
    else
      flush()
      current_logical_row = vim.deepcopy(cells)
    end
  end

  flush()

  return parsed_rows, new_delimiter_idx
end

-- Заполнение пробелами с учетом выравнивания
local function pad_cell(cell, width, align, ignore_markdown)
  local display_cell = ignore_markdown and strip_markdown_syntax(cell) or cell
  local cell_width = vim.fn.strdisplaywidth(display_cell)
  local padding = width - cell_width
  if padding <= 0 then
    return cell
  end

  if align == 'right' then
    return string.rep(' ', padding) .. cell
  elseif align == 'center' then
    local left_pad = math.floor(padding / 2)
    local right_pad = padding - left_pad
    return string.rep(' ', left_pad) .. cell .. string.rep(' ', right_pad)
  else
    return cell .. string.rep(' ', padding)
  end
end

-- Форматирование разделителя
local function format_separator_cell(width, align)
  if align == 'center' then
    return ':' .. string.rep('-', width - 2) .. ':'
  elseif align == 'left' then
    return ':' .. string.rep('-', width - 1)
  elseif align == 'right' then
    return string.rep('-', width - 1) .. ':'
  else
    return string.rep('-', width)
  end
end

-- Нахождение длины самого длинного слова в ячейке
local function get_max_word_width(cell, ignore_markdown)
  local max_word_w = 0
  local words = tokenize_text(cell)
  for _, word in ipairs(words) do
    local display_word = ignore_markdown and strip_markdown_syntax(word) or word
    local w = vim.fn.strdisplaywidth(display_word)
    max_word_w = math.max(max_word_w, w)
  end
  return max_word_w
end

-- Умный перенос текста ячейки на несколько строк с защитой спецвыражений
local function wrap_text(text, max_width, ignore_markdown)
  local display_text = ignore_markdown and strip_markdown_syntax(text) or text
  if vim.fn.strdisplaywidth(display_text) <= max_width then
    return { text }
  end

  local lines = {}
  local words = tokenize_text(text)

  if #words == 0 then
    return { '' }
  end

  local current_line = ''
  for _, word in ipairs(words) do
    local display_word = ignore_markdown and strip_markdown_syntax(word) or word
    local word_width = vim.fn.strdisplaywidth(display_word)

    if word_width > max_width then
      -- Токен шире колонки. Не режем его НИКОГДА: разорванная ссылка, HTML-тег
      -- или code span - это испорченный документ, а не косметика. Колонка и так
      -- рассчитана по самому длинному токену (calculate_target_widths), поэтому
      -- сюда попадают только вырожденные случаи - кладём токен отдельной строкой
      -- и миримся с тем, что она выступит за расчётную ширину
      if current_line ~= '' then
        table.insert(lines, current_line)
      end
      current_line = word
    else
      local space = (current_line == '') and '' or ' '
      local line_with_word = current_line .. space .. word
      local display_line_with_word = ignore_markdown and strip_markdown_syntax(line_with_word)
        or line_with_word

      if vim.fn.strdisplaywidth(display_line_with_word) > max_width then
        table.insert(lines, current_line)
        current_line = word
      else
        current_line = line_with_word
      end
    end
  end

  if current_line ~= '' then
    table.insert(lines, current_line)
  end

  return lines
end

-- Пропорциональное распределение доступной ширины с защитой от разрыва слов
local function calculate_target_widths(natural_widths, max_word_widths, available_width)
  local N = #natural_widths
  local total_natural = 0
  for i = 1, N do
    total_natural = total_natural + natural_widths[i]
  end

  if total_natural <= available_width then
    return natural_widths
  end

  local target_widths = {}
  local sum_min_widths = 0
  local min_widths = {}

  for i = 1, N do
    local min_w = math.max(max_word_widths[i] or 0, 3)
    min_w = math.min(min_w, natural_widths[i])
    min_widths[i] = min_w
    sum_min_widths = sum_min_widths + min_w
  end

  -- Минимумы не влезают в доступную ширину: ужимать их нельзя - это порвало бы
  -- ссылку, тег или code span. Отдаём ровно минимумы: таблица выйдет за
  -- max_width, но будет настолько узкой, насколько это вообще возможно
  if sum_min_widths > available_width then
    return min_widths
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

-- Форматирование таблицы
local function format_single_table(table_lines)
  if #table_lines == 0 then
    return nil
  end

  local indent = table_lines[1]:match('^(%s*)') or ''
  local indent_width = vim.fn.strdisplaywidth(indent)

  -- Парсим строки и автоматически склеиваем перенесенные ячейки
  local parsed_rows, separator_idx = parse_table_lines(table_lines)

  local alignments = {}
  if separator_idx and parsed_rows[separator_idx] then
    local sep_cells = parsed_rows[separator_idx]
    for col_idx, cell in ipairs(sep_cells) do
      local align = 'default'
      local has_left = cell:sub(1, 1) == ':'
      local has_right = cell:sub(-1, -1) == ':'
      if has_left and has_right then
        align = 'center'
      elseif has_left then
        align = 'left'
      elseif has_right then
        align = 'right'
      end
      alignments[col_idx] = align
    end
  end

  local max_cols = 0
  for _, cells in ipairs(parsed_rows) do
    max_cols = math.max(max_cols, #cells)
  end

  local max_w = config.max_width
  local available_width = max_w - indent_width - (3 * max_cols) - 1

  local natural_widths = {}
  for row_idx, cells in ipairs(parsed_rows) do
    if row_idx ~= separator_idx then
      for col_idx, cell in ipairs(cells) do
        local display_cell = config.ignore_markdown_syntax and strip_markdown_syntax(cell) or cell
        local width = vim.fn.strdisplaywidth(display_cell)
        natural_widths[col_idx] = math.max(natural_widths[col_idx] or 0, width)
      end
    end
  end

  local max_word_widths = {}
  for row_idx, cells in ipairs(parsed_rows) do
    if row_idx ~= separator_idx then
      for col_idx, cell in ipairs(cells) do
        local word_w = get_max_word_width(cell, config.ignore_markdown_syntax)
        max_word_widths[col_idx] = math.max(max_word_widths[col_idx] or 0, word_w)
      end
    end
  end

  -- Шапка не переносится, поэтому её ячейка целиком - тоже жёсткий минимум
  -- колонки, а не только самый длинный токен в ней
  local header_idx = separator_idx and (separator_idx - 1) or nil
  if header_idx and parsed_rows[header_idx] then
    for col_idx, cell in ipairs(parsed_rows[header_idx]) do
      local display_cell = config.ignore_markdown_syntax and strip_markdown_syntax(cell) or cell
      local width = vim.fn.strdisplaywidth(display_cell)
      max_word_widths[col_idx] = math.max(max_word_widths[col_idx] or 0, width)
    end
  end

  for col_idx = 1, max_cols do
    if (natural_widths[col_idx] or 0) < 3 then
      natural_widths[col_idx] = 3
    end
  end

  local target_widths = calculate_target_widths(natural_widths, max_word_widths, available_width)

  local formatted_lines = {}
  local is_first_data_row = true

  for row_idx, cells in ipairs(parsed_rows) do
    if row_idx == separator_idx then
      local formatted_cells = {}
      for col_idx = 1, max_cols do
        local align = alignments[col_idx] or 'default'
        local width = target_widths[col_idx]
        table.insert(formatted_cells, format_separator_cell(width, align))
      end
      table.insert(formatted_lines, indent .. '| ' .. table.concat(formatted_cells, ' | ') .. ' |')
    else
      -- Если это строка данных (и не самая первая), рисуем разделительную линию между ячейками
      if separator_idx and row_idx > separator_idx then
        if config.row_separators and not is_first_data_row then
          local formatted_cells = {}
          for col_idx = 1, max_cols do
            local align = alignments[col_idx] or 'default'
            local width = target_widths[col_idx]
            table.insert(formatted_cells, format_separator_cell(width, align))
          end
          table.insert(
            formatted_lines,
            indent .. '| ' .. table.concat(formatted_cells, ' | ') .. ' |'
          )
        end
        is_first_data_row = false
      end

      -- Перенос содержимого ячеек. Шапку не переносим никогда: разделитель
      -- обязан быть второй строкой таблицы, иначе для GFM это уже не таблица -
      -- prettier на следующем сохранении разберёт её как абзац и развалит файл
      local is_header = separator_idx and row_idx < separator_idx
      local wrapped_cols = {}
      local row_height = 1
      for col_idx = 1, max_cols do
        local cell = cells[col_idx] or ''
        local width = target_widths[col_idx]
        local wrapped = is_header and { cell }
          or wrap_text(cell, width, config.ignore_markdown_syntax)
        wrapped_cols[col_idx] = wrapped
        row_height = math.max(row_height, #wrapped)
      end

      for h = 1, row_height do
        local formatted_cells = {}
        for col_idx = 1, max_cols do
          local cell_line = wrapped_cols[col_idx][h] or ''
          local align = alignments[col_idx] or 'default'
          local width = target_widths[col_idx]
          table.insert(
            formatted_cells,
            pad_cell(cell_line, width, align, config.ignore_markdown_syntax)
          )
        end
        table.insert(
          formatted_lines,
          indent .. '| ' .. table.concat(formatted_cells, ' | ') .. ' |'
        )
      end
    end
  end

  return formatted_lines
end

-- Страховка от порчи документа: результат обязан быть валидной GFM-таблицей -
-- разделитель второй строкой и одинаковое число колонок во всех строках.
-- Если инвариант нарушен, блок лучше оставить как был, чем испортить файл
local function is_valid_table(lines)
  if #lines < 2 then
    return false
  end

  local header = split_row(lines[1])
  if #header == 0 or is_separator_row(header) then
    return false
  end

  if not is_separator_row(split_row(lines[2])) then
    return false
  end

  for _, line in ipairs(lines) do
    if #split_row(line) ~= #header then
      return false
    end
  end

  return true
end

-- Поиск всех блоков таблиц в файле
local function find_table_blocks(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local blocks = {}
  local in_table = false
  local table_start = nil
  local table_lines = {}

  for i = 1, #lines do
    local line = lines[i]
    local trimmed = line:gsub('^%s+', ''):gsub('%s+$', '')
    local is_table_line = trimmed:sub(1, 1) == '|' and trimmed:sub(-1, -1) == '|'

    if is_table_line then
      if not in_table then
        in_table = true
        table_start = i
        table_lines = {}
      end
      table.insert(table_lines, line)
    else
      if in_table then
        table.insert(blocks, {
          start_line = table_start,
          end_line = i - 1,
          lines = table_lines,
        })
        in_table = false
      end
    end
  end

  if in_table then
    table.insert(blocks, {
      start_line = table_start,
      end_line = #lines,
      lines = table_lines,
    })
  end

  return blocks
end

-- Запуск форматирования всех таблиц в буфере
local function format_markdown_tables_in_buffer()
  local bufnr = vim.api.nvim_get_current_buf()
  local blocks = find_table_blocks(bufnr)
  if #blocks == 0 then
    return
  end

  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local cursor_row = cursor_pos[1]
  local cursor_col = cursor_pos[2]
  local row_offset = 0
  local changed = false

  -- Обрабатываем таблицы снизу вверх, чтобы изменения индексов строк не ломали адресацию выше
  for i = #blocks, 1, -1 do
    local block = blocks[i]
    local formatted = format_single_table(block.lines)
    if formatted and is_valid_table(formatted) then
      vim.api.nvim_buf_set_lines(bufnr, block.start_line - 1, block.end_line, false, formatted)
      changed = true

      -- Если таблица изменила высоту выше положения курсора, корректируем его строку
      if block.end_line < cursor_row then
        local old_line_count = block.end_line - block.start_line + 1
        local new_line_count = #formatted
        row_offset = row_offset + (new_line_count - old_line_count)
      end
    end
  end

  if changed then
    local total_lines = vim.api.nvim_buf_line_count(bufnr)
    local new_cursor_row = math.max(1, math.min(total_lines, cursor_row + row_offset))
    pcall(vim.api.nvim_win_set_cursor, 0, { new_cursor_row, cursor_col })
  end
end

-- Автокоманда для форматирования перед записью буфера
vim.api.nvim_create_autocmd('BufWritePre', {
  group = table_format_group,
  pattern = '*',
  callback = function(args)
    -- Тот же переключатель, что и у conform (<leader>uf): "Disabled autoformat"
    -- обязан отключать вообще всё форматирование при сохранении
    if vim.g.disable_autoformat or vim.b[args.buf].disable_autoformat then
      return
    end

    if vim.bo[args.buf].filetype == 'markdown' then
      format_markdown_tables_in_buffer()
    end
  end,
})
