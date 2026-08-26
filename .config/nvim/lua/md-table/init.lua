-- Форматтер markdown-таблиц.
--
-- КОНТРАКТ:
--   * все таблицы буфера переформатируются на каждом сохранении (BufWritePre),
--     после prettierd - последнее слово по ширине таблиц за этим модулем;
--   * шапка не переносится никогда: разделитель обязан быть второй строкой
--     таблицы, иначе для GFM это уже не таблица;
--   * первая колонка не переносится: её непустота - признак начала новой
--     логической строки;
--   * между логическими строками ставится линия из ROW_RULE_CHAR
--     (см. config.row_separators);
--   * блок, который не является GFM-таблицей (нет строки-разделителя) или
--     лежит внутри ограждённого блока кода, не трогается вообще;
--   * всё форматирование отключается общим переключателем <leader>uf
--     (vim.g.disable_autoformat / vim.b[buf].disable_autoformat), тем же, что
--     у conform.
--
-- Ручной прогон: :MdTableFormat
-- Тесты: nvim --headless -c "lua require('md-table.tests').run()" -c qa

local M = {}

local defaults = {
  -- Если true, спецсимволы разметки (**, `, *, ~~, ссылки) НЕ учитываются при
  -- расчете ширины. Держим false: в файле таблица выравнивается по "сырой"
  -- ширине, как её видят prettier, git diff и GitHub. Компенсацию скрытых
  -- (conceal) символов на экране берёт на себя render-markdown с
  -- pipe_table.cell = 'padded'.
  ignore_markdown_syntax = false,

  -- Максимальная ширина таблицы. ДОЛЖНА совпадать с printWidth в
  -- ~/.prettierrc.mjs: рассинхронизация проявится как "таблицы то влезают,
  -- то нет".
  max_width = 80,

  -- Комфортная ширина переносимой колонки. Жёсткий минимум колонки задаётся
  -- длиной неразрывного токена, поэтому колонка с кодом забирает ширину, а
  -- колонка с прозой остаётся на своём полу и рассыпается в лесенку. Колонка,
  -- чья самая высокая ячейка занимает min_wrapped_lines строк и больше,
  -- расширяется до min_wrapped_width - но никогда не шире, чем нужно её
  -- содержимому. Отдать ширину соседям при этом нечего (они стоят на
  -- неразрывных токенах), поэтому таблица может выйти за max_width.
  -- min_wrapped_width = 0 отключает правило.
  min_wrapped_width = 20,
  min_wrapped_lines = 3,

  -- Линия между логическими строками таблицы:
  --   'multiline' - только там, где соседняя строка занимает больше одной
  --                 строки (ради чего разделитель и нужен - видно, где
  --                 многострочная строка кончается), без шума в таблицах
  --                 из однострочных строк;
  --   true        - между всеми строками;
  --   false       - не рисовать.
  --
  -- Линия рисуется символом ROW_RULE_CHAR, а НЕ дефисами: |---|---| для GFM -
  -- валидный разделитель шапки, парсер начинает с него новую таблицу, и строка
  -- перед ним отрисовывается как шапка, то есть жирной.
  row_separators = true,
}

local config = vim.deepcopy(defaults)

-- Символ линии между строками. Требования:
--   * не '-' и не ':' - иначе GFM считает строку разделителем шапки;
--   * не создающий инлайн-разметку: серия из 3+ тильд разделителем
--     зачёркивания в GFM не является (там 1-2 тильды), а минимальная ширина
--     колонки здесь 3, поэтому '~' безопасен, тогда как '_' дал бы курсив;
--   * ровно один байт. Наблюдение: на многобайтовом '─' в связке с
--     render-markdown pipe_table.cell = 'padded' раскладка таблицы
--     разъезжалась и последняя колонка рисовалась битым глифом. Механизм не
--     выяснен (кириллица в ячейках при этом работает нормально), поэтому это
--     именно наблюдение, а не объяснение.
local ROW_RULE_CHAR = '~'
local RULE_PATTERN = '^' .. vim.pesc(ROW_RULE_CHAR) .. '+$'

local function trim(str)
  return (str:gsub('^%s+', ''):gsub('%s+$', ''))
end

-- Токенизатор текста. Слово - это ровно то, что стоит между пробелами:
-- склеивать соседние токены через пробел нельзя, иначе `vimp-tanks`'s
-- превращается в `vimp-tanks` 's, то есть форматтер правит текст документа.
-- Пробел ВНУТРИ защищённой конструкции (code span, **жирный**, ссылка, HTML-тег)
-- слово не разрывает
local function tokenize_text(text)
  local tokens = {}
  local i = 1
  local len = #text

  -- Если в позиции pos начинается защищённая конструкция, вернуть её последний
  -- байт, иначе nil
  local function protected_end(pos)
    local _, e = text:find('^!?%[[^%]]-%]%([^%)]-%)', pos) -- [текст](url)
    if e then
      return e
    end

    _, e = text:find('^<[^<>]->', pos) -- <img src="..." alt="...">
    if e then
      return e
    end

    for _, marker in ipairs({ '**', '~~', '__' }) do
      if text:sub(pos, pos + 1) == marker then
        local close = text:find(marker, pos + 2, true)
        if close then
          return close + 1
        end
      end
    end

    if text:sub(pos, pos) == '`' then
      local close = text:find('`', pos + 1, true)
      if close then
        return close
      end
    end

    return nil
  end

  while i <= len do
    local _, ws_end = text:find('^%s+', i)
    if ws_end then
      i = ws_end + 1
    end

    if i > len then
      break
    end

    local token_start = i
    while i <= len and not text:sub(i, i):match('%s') do
      i = (protected_end(i) or i) + 1
    end
    table.insert(tokens, text:sub(token_start, i - 1))
  end

  return tokens
end

-- Вспомогательная функция очистки разметки (на базе безопасных токенов)
local function strip_markdown_syntax(str)
  -- 1. Сначала убираем ссылки и картинки (они могут содержать пробелы)
  str = str:gsub('!%[([^%]]-)%]%([^%)]-%)', '%1')
  str = str:gsub('%[([^%]]-)%]%([^%)]-%)', '%1')

  -- 2. Разбиваем на токены для безопасной очистки без повреждения путей/глобов
  local tokens = tokenize_text(str)
  local stripped_tokens = {}

  for _, token in ipairs(tokens) do
    local stripped = token
    -- Проверка длины обязательна: у токена '**' диапазоны sub(1, 2) и
    -- sub(-2, -1) перекрываются, sub(3, -3) дал бы пустую строку и ширину 0
    if token:sub(1, 1) == '`' and token:sub(-1, -1) == '`' and #token > 2 then
      stripped = token:sub(2, -2)
    elseif token:sub(1, 2) == '**' and token:sub(-2, -1) == '**' and #token > 4 then
      stripped = strip_markdown_syntax(token:sub(3, -3))
    elseif token:sub(1, 2) == '__' and token:sub(-2, -1) == '__' and #token > 4 then
      stripped = strip_markdown_syntax(token:sub(3, -3))
    elseif token:sub(1, 2) == '~~' and token:sub(-2, -1) == '~~' and #token > 4 then
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

-- Единственное место, где считается отображаемая ширина строки таблицы.
-- Здесь же учитывается экранирование: '\|' занимает в ячейке два байта, но
-- одну колонку - и в render-markdown, и на GitHub.
-- vim.fn.* - переход из Lua в Vimscript, поэтому результат кэшируется:
-- wrap_text зовёт эту функцию для каждого слова и каждой строки-кандидата.
local width_cache = {}

local function display_width(str)
  local cached = width_cache[str]
  if cached then
    return cached
  end

  local text = config.ignore_markdown_syntax and strip_markdown_syntax(str) or str
  local _, escaped = text:gsub('\\|', '')
  local width = vim.fn.strdisplaywidth(text) - escaped
  width_cache[str] = width
  return width
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
    cells[idx] = trim(cell)
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

-- Проверка на строку-линию, нарисованную самим форматтером (см. ROW_RULE_CHAR).
-- Для GFM это обычная строка данных, поэтому распознаём её сами.
-- Край: ячейка данных, состоящая только из ROW_RULE_CHAR, была бы опознана как
-- линия и выброшена. Требование длины >= 3 во ВСЕХ ячейках делает это
-- маловероятным - минимальная ширина колонки как раз 3
local function is_rule_row(cells)
  if #cells == 0 then
    return false
  end
  for _, cell in ipairs(cells) do
    if #cell < 3 or not cell:match(RULE_PATTERN) then
      return false
    end
  end
  return true
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

-- Проверка на строку-продолжение (перенос предыдущей логической строки):
-- первая колонка пустая
local function is_continuation_row(cells)
  return (cells[1] or '') == ''
end

-- Склейка ячеек одной логической строки, разложенной по нескольким строкам
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

-- Строка блока начинает новую логическую строку таблицы (не разделитель,
-- не линия, не продолжение). По этому же признаку курсор переносится со старой
-- раскладки блока на новую
local function starts_logical_row(line)
  local cells = split_row(trim(line))
  return not is_separator_row(cells) and not is_rule_row(cells) and not is_continuation_row(cells)
end

-- Номер логической строки, к которой относится line_idx внутри блока
local function logical_row_index(lines, line_idx)
  local n = 0
  for i = 1, math.min(line_idx, #lines) do
    if starts_logical_row(lines[i]) then
      n = n + 1
    end
  end
  return math.max(n, 1)
end

-- Первая строка n-й логической строки блока
local function logical_row_line(lines, n)
  local count = 0
  for i = 1, #lines do
    if starts_logical_row(lines[i]) then
      count = count + 1
      if count == n then
        return i
      end
    end
  end
  return #lines
end

-- Умный парсинг табличных строк с обратным склеиванием перенесенных ячеек.
-- Возвращает nil, если блок не является GFM-таблицей (нет строки-разделителя).
-- continuation_override принудительно включает/выключает эвристику
-- "пустая первая ячейка = продолжение"; третьим значением возвращается признак
-- того, что блок читается двояко (см. format_single_table)
local function parse_table_lines(table_lines, continuation_override)
  local all_rows = {}
  for _, line in ipairs(table_lines) do
    table.insert(all_rows, split_row(trim(line)))
  end

  -- Находим первый разделитель - он отделяет шапку от данных
  local delimiter_idx = nil
  local sep_count = 0
  local has_rule = false
  for idx, cells in ipairs(all_rows) do
    if is_separator_row(cells) then
      sep_count = sep_count + 1
      if not delimiter_idx then
        delimiter_idx = idx
      end
    elseif is_rule_row(cells) then
      has_rule = true
    end
  end

  -- Блок pipe-строк без разделителя - не таблица GFM. Раньше здесь стоял
  -- фолбэк delimiter_idx = min(2, #all_rows): он назначал разделителем обычную
  -- строку данных, и она затиралась дефисами, то есть текст пропадал
  if not delimiter_idx then
    return nil, nil
  end

  -- Больше одного разделителя - таблица уже в стиле grid: границы логических
  -- строк заданы разделителями, и первая колонка тоже могла быть перенесена,
  -- поэтому эвристика "пустая первая ячейка" здесь не применима
  local grid_style = sep_count > 1

  -- Эвристика "пустая первая ячейка = продолжение" применима только к блокам,
  -- которые писал сам форматтер: в чужой таблице пустая первая ячейка -
  -- нормальные данные, и склейка потеряла бы логическую строку.
  -- Признак авторства - наличие строк-линий (или разделителей grid-стиля).
  -- Если их нет, а строки с пустой первой ячейкой есть, блок читается двояко:
  -- разрешает спор format_single_table
  local body_start = delimiter_idx + 1
  local has_continuation = false
  for i = body_start, #all_rows do
    if is_continuation_row(all_rows[i]) then
      has_continuation = true
      break
    end
  end

  local ambiguous = has_continuation and not has_rule and not grid_style
  local allow_continuation = has_rule or grid_style
  if continuation_override ~= nil then
    allow_continuation = continuation_override
  end

  local parsed_rows = {}
  -- Шапка в GFM - ровно одна строка (разделитель обязан быть второй строкой
  -- таблицы). Всё, что стоит до разделителя, склеиваем в одну логическую строку:
  -- это же чинит файлы, где шапку уже успело разорвать на несколько строк
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

  -- Переносим главный разделитель
  table.insert(parsed_rows, all_rows[delimiter_idx])
  local new_delimiter_idx = #parsed_rows

  -- Склеиваем строки данных обратно перед новым форматированием.
  -- Логическая строка закрывается линией/разделителем либо началом строки
  -- с непустой первой колонкой
  local current_logical_row = nil

  local function flush()
    if current_logical_row then
      table.insert(parsed_rows, current_logical_row)
      current_logical_row = nil
    end
  end

  for i = body_start, #all_rows do
    local cells = all_rows[i]
    if is_separator_row(cells) or is_rule_row(cells) then
      -- Линия, добавленная самим форматтером (или разделитель из файлов,
      -- отформатированных прежней версией): она лишь закрывает логическую
      -- строку и заново вставляется при форматировании
      flush()
    elseif
      current_logical_row
      and allow_continuation
      and (grid_style or is_continuation_row(cells))
    then
      merge_cells(current_logical_row, cells)
    else
      flush()
      current_logical_row = vim.deepcopy(cells)
    end
  end

  flush()

  return parsed_rows, new_delimiter_idx, ambiguous
end

-- Заполнение пробелами с учетом выравнивания
local function pad_cell(cell, width, align)
  local padding = width - display_width(cell)
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
local function get_max_word_width(cell)
  local max_word_w = 0
  for _, word in ipairs(tokenize_text(cell)) do
    max_word_w = math.max(max_word_w, display_width(word))
  end
  return max_word_w
end

-- Умный перенос текста ячейки на несколько строк с защитой спецвыражений
local function wrap_text(text, max_width)
  if display_width(text) <= max_width then
    return { text }
  end

  local lines = {}
  local words = tokenize_text(text)

  if #words == 0 then
    return { '' }
  end

  local current_line = ''
  for _, word in ipairs(words) do
    local word_width = display_width(word)

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

      if display_width(line_with_word) > max_width then
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

-- Комфортный минимум для переносимых колонок.
-- Проход только расширяет колонки и никогда не сужает, поэтому итерации до
-- неподвижной точки не нужны - хватает одного прохода.
local function apply_comfort_widths(parsed_rows, separator_idx, max_cols, natural_widths, target_widths)
  if config.min_wrapped_width <= 0 then
    return
  end

  -- первую колонку пропускаем: она не переносится по построению
  for col_idx = 2, max_cols do
    local width = target_widths[col_idx]

    -- natural > width означает "колонка будет переноситься" - тот же факт, что
    -- и "в колонке есть многострочная ячейка", но без цикла: многострочность
    -- зависит от ширины, которую мы здесь и определяем
    if width < config.min_wrapped_width and (natural_widths[col_idx] or 0) > width then
      local height = 1
      for row_idx = separator_idx + 1, #parsed_rows do
        local cell = parsed_rows[row_idx][col_idx] or ''
        height = math.max(height, #wrap_text(cell, width))
      end

      if height >= config.min_wrapped_lines then
        -- потолок natural_widths обязателен: расширять колонку сверх того, что
        -- нужно её содержимому, значит гнать таблицу вширь ради пустот
        target_widths[col_idx] =
          math.max(width, math.min(natural_widths[col_idx], config.min_wrapped_width))
      end
    end
  end
end

-- Пропорциональное распределение доступной ширины с защитой от разрыва слов
local function calculate_target_widths(natural_widths, max_word_widths, available_width)
  local N = #natural_widths
  local total_natural = 0
  for i = 1, N do
    total_natural = total_natural + natural_widths[i]
  end

  -- копия обязательна: результат мутирует apply_comfort_widths, а
  -- natural_widths служит ей потолком
  if total_natural <= available_width then
    return vim.deepcopy(natural_widths)
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

-- Отрисовка разобранной таблицы
local function render_table(indent, parsed_rows, separator_idx)
  local indent_width = vim.fn.strdisplaywidth(indent)

  local alignments = {}
  for col_idx, cell in ipairs(parsed_rows[separator_idx]) do
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

  local max_cols = 0
  for _, cells in ipairs(parsed_rows) do
    max_cols = math.max(max_cols, #cells)
  end

  local available_width = config.max_width - indent_width - (3 * max_cols) - 1

  -- Естественная ширина колонки и её жёсткий минимум считаются одним проходом.
  -- Что не переносится, то целиком становится жёстким минимумом:
  --  * шапка - иначе разделитель перестанет быть второй строкой таблицы;
  --  * первая колонка - на её непустоте держится распознавание переноса
  local header_idx = separator_idx - 1
  local natural_widths = {}
  local max_word_widths = {}
  for row_idx, cells in ipairs(parsed_rows) do
    if row_idx ~= separator_idx then
      for col_idx, cell in ipairs(cells) do
        local width = display_width(cell)
        natural_widths[col_idx] = math.max(natural_widths[col_idx] or 0, width)

        local word_w = get_max_word_width(cell)
        if col_idx == 1 or row_idx == header_idx then
          word_w = math.max(word_w, width)
        end
        max_word_widths[col_idx] = math.max(max_word_widths[col_idx] or 0, word_w)
      end
    end
  end

  for col_idx = 1, max_cols do
    if (natural_widths[col_idx] or 0) < 3 then
      natural_widths[col_idx] = 3
    end
  end

  local target_widths = calculate_target_widths(natural_widths, max_word_widths, available_width)
  apply_comfort_widths(parsed_rows, separator_idx, max_cols, natural_widths, target_widths)

  -- Раскладываем строки данных заранее: чтобы решить, нужна ли линия между
  -- соседями, надо знать их высоту, а она известна только после переноса
  local rendered = {}
  for row_idx = separator_idx + 1, #parsed_rows do
    local cells = parsed_rows[row_idx]
    local wrapped_cols = {}
    local height = 1
    for col_idx = 1, max_cols do
      local cell = cells[col_idx] or ''
      -- первую колонку не переносим: пустая первая ячейка - единственный
      -- признак, по которому строка продолжения отличается от новой строки
      local wrapped = col_idx == 1 and { cell } or wrap_text(cell, target_widths[col_idx])
      wrapped_cols[col_idx] = wrapped
      height = math.max(height, #wrapped)
    end
    rendered[#rendered + 1] = { cols = wrapped_cols, height = height }
  end

  local function build_row(get_cell)
    local formatted_cells = {}
    for col_idx = 1, max_cols do
      formatted_cells[col_idx] = get_cell(col_idx, target_widths[col_idx])
    end
    return indent .. '| ' .. table.concat(formatted_cells, ' | ') .. ' |'
  end

  local formatted_lines = {}

  -- Шапка. Не переносим никогда: разделитель обязан быть второй строкой
  -- таблицы, иначе для GFM это уже не таблица - prettier на следующем
  -- сохранении разберёт её как абзац и развалит файл
  for row_idx = 1, separator_idx - 1 do
    local cells = parsed_rows[row_idx]
    formatted_lines[#formatted_lines + 1] = build_row(function(col_idx, width)
      return pad_cell(cells[col_idx] or '', width, alignments[col_idx] or 'default')
    end)
  end

  -- Разделитель шапки - единственный, который обязан быть из дефисов
  formatted_lines[#formatted_lines + 1] = build_row(function(col_idx, width)
    return format_separator_cell(width, alignments[col_idx] or 'default')
  end)

  local function needs_rule(prev, next_)
    if not config.row_separators then
      return false
    end
    if config.row_separators == 'multiline' then
      return prev.height > 1 or next_.height > 1
    end
    return true
  end

  for i, row in ipairs(rendered) do
    if i > 1 and needs_rule(rendered[i - 1], row) then
      formatted_lines[#formatted_lines + 1] = build_row(function(_, width)
        return string.rep(ROW_RULE_CHAR, width)
      end)
    end

    for h = 1, row.height do
      formatted_lines[#formatted_lines + 1] = build_row(function(col_idx, width)
        return pad_cell(row.cols[col_idx][h] or '', width, alignments[col_idx] or 'default')
      end)
    end
  end

  return formatted_lines
end

-- Форматирование таблицы. nil означает "оставить блок как есть"
local function format_single_table(table_lines)
  if #table_lines == 0 then
    return nil
  end

  width_cache = {}

  local indent = table_lines[1]:match('^(%s*)') or ''

  -- Сначала читаем блок как вывод этого же форматтера: строки с пустой первой
  -- ячейкой - продолжение предыдущей логической строки
  local parsed_rows, separator_idx, ambiguous = parse_table_lines(table_lines, true)
  if not parsed_rows then
    return nil
  end

  local formatted = render_table(indent, parsed_rows, separator_idx)

  -- Блок без строк-линий, где есть строки с пустой первой ячейкой, читается
  -- двояко: это либо одна перенесённая логическая строка, либо чужая таблица,
  -- в которой пустая первая ячейка - нормальные данные. Спор решает проверка:
  -- если склеенная интерпретация воспроизводит блок в точности, его писал этот
  -- же форматтер. Иначе строки самостоятельные, и склейка потеряла бы
  -- логическую строку
  if ambiguous and not lines_equal(formatted, table_lines) then
    parsed_rows, separator_idx = parse_table_lines(table_lines, false)
    formatted = render_table(indent, parsed_rows, separator_idx)
  end

  return formatted
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

-- Поиск всех блоков таблиц в файле.
-- Ограждённые блоки кода пропускаются: пример таблицы внутри ```markdown или
-- ASCII-арт внутри ```text - это содержимое документа, а не таблица
local function find_table_blocks(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
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
      -- закрывающая ограда должна быть того же типа и не короче открывающей
      if fence_mark and fence_mark:sub(1, 1) == fence:sub(1, 1) and #fence_mark >= #fence then
        fence = nil
      end
    elseif fence_mark then
      close_block(i - 1) -- ограда обрывает блок, начатый выше
      fence = fence_mark
    elseif trimmed:sub(1, 1) == '|' and trimmed:sub(-1, -1) == '|' then
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

-- Форматирование всех таблиц указанного буфера
function M.format_buffer(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(bufnr) or not vim.bo[bufnr].modifiable then
    return
  end

  local blocks = find_table_blocks(bufnr)
  if #blocks == 0 then
    return
  end

  -- Курсор трогаем только если буфер и правда показан в текущем окне: при
  -- :wall, :bufdo w и автосейве записываемый буфер не совпадает с текущим
  local win = vim.api.nvim_get_current_win()
  local track_cursor = vim.api.nvim_win_get_buf(win) == bufnr
  local cursor_row, cursor_col = 1, 0
  if track_cursor then
    local pos = vim.api.nvim_win_get_cursor(win)
    cursor_row, cursor_col = pos[1], pos[2]
  end

  local row_offset = 0
  -- Курсор внутри изменившейся таблицы: extmark здесь не помогает - блок
  -- переписывается целиком, и метка схлопывается к его границе. Вместо этого
  -- переносим курсор на ту же логическую строку таблицы в новой раскладке
  local inside = nil
  local changed = false

  -- Обрабатываем таблицы снизу вверх, чтобы изменения индексов строк не ломали
  -- адресацию выше
  for i = #blocks, 1, -1 do
    local block = blocks[i]
    local formatted = format_single_table(block.lines)
    -- no-op не пишем: запись всё равно трогает буфер (флаг modified,
    -- TextChanged, extmark'и расширений) и добавляет шаг в undo
    if formatted and is_valid_table(formatted) and not lines_equal(formatted, block.lines) then
      if changed then
        -- одно сохранение = один шаг undo
        vim.api.nvim_buf_call(bufnr, function()
          pcall(vim.cmd, 'undojoin')
        end)
      end
      vim.api.nvim_buf_set_lines(bufnr, block.start_line - 1, block.end_line, false, formatted)
      changed = true

      if track_cursor then
        if block.end_line < cursor_row then
          row_offset = row_offset + (#formatted - (block.end_line - block.start_line + 1))
        elseif block.start_line <= cursor_row then
          local n = logical_row_index(block.lines, cursor_row - block.start_line + 1)
          inside = {
            start_line = block.start_line,
            rel = logical_row_line(formatted, n) - 1,
          }
        end
      end
    end
  end

  if track_cursor and changed then
    local base = inside and (inside.start_line + inside.rel) or cursor_row
    local total = vim.api.nvim_buf_line_count(bufnr)
    local row = math.max(1, math.min(total, base + row_offset))
    -- колонку клампим по фактической длине строки: она могла стать короче
    local line = vim.api.nvim_buf_get_lines(bufnr, row - 1, row, false)[1] or ''
    pcall(vim.api.nvim_win_set_cursor, win, { row, math.min(cursor_col, #line) })
  end
end

function M.setup(opts)
  config = vim.tbl_deep_extend('force', vim.deepcopy(defaults), opts or {})
  width_cache = {}

  vim.api.nvim_create_autocmd('BufWritePre', {
    group = vim.api.nvim_create_augroup('MarkdownTableAutoFormat', { clear = true }),
    -- pattern = '*' намеренно: гейтом служит filetype, который ловит и .mdx,
    -- и буферы с явно выставленным типом
    pattern = '*',
    callback = function(args)
      if not vim.bo[args.buf].modifiable then
        return
      end

      -- Тот же переключатель, что и у conform (<leader>uf): "Disabled autoformat"
      -- обязан отключать вообще всё форматирование при сохранении
      if vim.g.disable_autoformat or vim.b[args.buf].disable_autoformat then
        return
      end

      if vim.bo[args.buf].filetype == 'markdown' then
        M.format_buffer(args.buf)
      end
    end,
  })

  vim.api.nvim_create_user_command('MdTableFormat', function()
    M.format_buffer(0)
  end, { desc = 'Отформатировать markdown-таблицы в буфере' })
end

-- Чистые функции над строками - для тестов (md-table/tests.lua)
M._internal = {
  tokenize_text = tokenize_text,
  strip_markdown_syntax = strip_markdown_syntax,
  display_width = display_width,
  split_row = split_row,
  parse_table_lines = parse_table_lines,
  wrap_text = wrap_text,
  calculate_target_widths = calculate_target_widths,
  format_single_table = format_single_table,
  is_valid_table = is_valid_table,
  find_table_blocks = find_table_blocks,
  set_config = function(opts)
    config = vim.tbl_deep_extend('force', vim.deepcopy(defaults), opts or {})
    width_cache = {}
  end,
}

return M
