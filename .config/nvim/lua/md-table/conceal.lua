-- Компенсация conceal для таблиц md-table.
--
-- Файл md-table выравнивает по СЫРОЙ ширине - так таблицу видят prettier,
-- git diff, GitHub и любой редактор без conceal. Neovim же прячет инлайн-
-- разметку (`code_span_delimiter`, `emphasis_delimiter`, синтаксис ссылок,
-- слэш в `\|` - всё это конциллит собственный запрос
-- queries/markdown_inline/highlights.scm), и на экране колонки разъезжаются:
-- на docs/en/network.md правый край гулял на 49 колонок.
--
-- Раньше это компенсировал render-markdown (pipe_table.cell = 'padded').
-- Здесь то же самое делается своими силами, чтобы md-table не зависел от
-- чужих настроек. Компенсация ТОЛЬКО экранная: буфер и файл не меняются.
--
-- Компенсация локальна - каждая ячейка получает назад ровно то, что у неё
-- отняли, без оглядки на соседние строки:
--
--   padding = display_width(cell) - (strdisplaywidth(cell) - hidden)
--           = hidden - (число экранированных труб)
--
-- потому что display_width вычитает экранирование ровно там же, где его
-- прячет conceal.

local M = {}

local ns = vim.api.nvim_create_namespace('md_table_conceal')

local config, deps
local registered = false

-- [bufnr] = { tick = changedtick, rows = { [row] = отступы или false } }
local cache = {}

local function trim(str)
  return (str:gsub('^%s+', ''):gsub('%s+$', ''))
end

local function is_table_line(line)
  local t = trim(line)
  return #t > 1 and t:sub(1, 1) == '|' and t:sub(-1, -1) == '|'
end

---Скрытые (concealed) участки строки: { { start_col, end_col, width }, ... }
---в байтовых, 0-based колонках. nil - парсера нет, решает вызывающий
local function ts_hidden_spans(buf, row)
  local ok, parser = pcall(vim.treesitter.get_parser, buf, 'markdown', { error = false })
  if not ok or not parser then
    return nil
  end

  -- разбираем только нужную строку, а не весь буфер
  local parsed = pcall(parser.parse, parser, { row, row + 1 })
  if not parsed then
    return nil
  end

  local spans = {}
  parser:for_each_tree(function(tree, ltree)
    local query = vim.treesitter.query.get(ltree:lang(), 'highlights')
    if not query then
      return
    end

    local root = tree:root()
    local root_start, _, root_end, _ = root:range()
    if row < root_start or row > root_end then
      return
    end

    for id, node, meta in query:iter_captures(root, buf, row, row + 1) do
      local conceal = meta.conceal or (meta[id] and meta[id].conceal)
      if conceal ~= nil then
        local sr, sc, er, ec = node:range()

        -- #offset! в запрос применяет потребитель, а не iter_captures:
        -- у backslash_escape стоит (#offset! @conceal 0 0 0 -1), и без этого
        -- '\|' посчитался бы как две скрытые колонки вместо одной
        local offset = meta[id] and meta[id].offset
        if offset then
          sr = sr + tonumber(offset[1])
          sc = sc + tonumber(offset[2])
          er = er + tonumber(offset[3])
          ec = ec + tonumber(offset[4])
        end

        if sr == row and er == row and ec > sc then
          local text = vim.api.nvim_buf_get_text(buf, sr, sc, er, ec, {})[1] or ''
          local width = vim.fn.strdisplaywidth(text) - vim.fn.strdisplaywidth(conceal)
          if width > 0 then
            spans[#spans + 1] = { sc, ec, width }
          end
        end
      end
    end
  end)

  return spans
end

---Ширина, которую в диапазоне строки добавляют или убирают ЧУЖИЕ extmark'и.
---Соседние плагины не только прячут, но и дорисовывают: render-markdown ставит
---на месте скрытой ссылки иконку '󰌹 ' inline virt_text шириной 2 колонки, и
---строка становится шире расчётной. Метки подсветки treesitter сюда не попадают
---(они ephemeral), так что двойного учёта с conceal-запросом нет
local function foreign_delta(buf, row, from, to)
  local ok, marks = pcall(vim.api.nvim_buf_get_extmarks, buf, -1,
    { row, from - 1 }, { row, to }, { details = true, overlap = true })
  if not ok then
    return 0
  end

  local delta = 0
  for _, mark in ipairs(marks) do
    local details = mark[4]
    if details and details.ns_id ~= ns then
      if details.virt_text and details.virt_text_pos == 'inline' then
        for _, chunk in ipairs(details.virt_text) do
          delta = delta + vim.fn.strdisplaywidth(chunk[1])
        end
      end
      if details.conceal and details.end_col then
        local text = vim.api.nvim_buf_get_text(buf, row, mark[3], row, details.end_col, {})[1] or ''
        delta = delta - (vim.fn.strdisplaywidth(text) - vim.fn.strdisplaywidth(details.conceal))
      end
    end
  end
  return delta
end

---Разбор строки, зависящий ТОЛЬКО от её текста: по ячейке - границы, скрытая
---conceal-запросом ширина и уже расставленные пробелы. Эту часть можно кэшировать
---по changedtick, потому что меняется она вместе с текстом
local function compute_cells(buf, row)
  local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1]
  if not line or not is_table_line(line) then
    return false
  end

  local spans = ts_hidden_spans(buf, row)
  local cells = {}

  for _, cell in ipairs(deps.cell_spans(line)) do
    local from, to = cell[1], cell[2] -- 1-based, включительно, участок между трубами
    local region = line:sub(from, to)
    local hidden

    if spans then
      hidden = 0
      for _, span in ipairs(spans) do
        -- span в 0-based колонках, region - в 1-based
        if span[1] >= from - 1 and span[2] <= to then
          hidden = hidden + span[3]
        end
      end
      -- экранированная труба уже вычтена из display_width при вёрстке файла,
      -- поэтому её скрытый слэш компенсировать не нужно
      local _, escaped_pipes = region:gsub('\\|', '')
      hidden = hidden - escaped_pipes
    else
      -- парсера нет: оцениваем по собственному стрипу разметки. Он же
      -- покрывает conceal классического vim-синтаксиса, который
      -- treesitter-запросом не виден
      local text = trim(region)
      hidden = vim.fn.strdisplaywidth(text) - vim.fn.strdisplaywidth(deps.strip(text))
    end

    -- сторону отступа берём из уже расставленных пробелов: у выровненной вправо
    -- ячейки их больше слева, у центрированной - поровну с обеих сторон
    local lead = #(region:match('^ *') or '')
    local trail = #(region:match(' *$') or '')

    cells[#cells + 1] = {
      from = from,
      to = to,
      hidden = hidden,
      content_start = from - 1 + lead,
      content_end = to - trail,
      lead = lead,
      trail = trail,
    }
  end

  return #cells > 0 and cells or false
end

---Отступы для строки: { { col, width }, ... } либо nil.
---Вклад чужих extmark'ов НЕ кэшируется: соседний плагин может расставить свои
---метки позже нашего расчёта, и закэшированная разница застряла бы до
---следующей правки буфера
local function row_padding(buf, row, cells)
  local marks = nil

  for _, cell in ipairs(cells) do
    local hidden = cell.hidden - foreign_delta(buf, row, cell.from, cell.to)

    if hidden > 0 then
      marks = marks or {}
      if cell.lead > cell.trail then
        marks[#marks + 1] = { cell.content_start, hidden }
      elseif cell.lead == cell.trail and cell.lead > 1 then
        local left = math.floor(hidden / 2)
        if left > 0 then
          marks[#marks + 1] = { cell.content_start, left }
        end
        if hidden - left > 0 then
          marks[#marks + 1] = { cell.content_end, hidden - left }
        end
      else
        marks[#marks + 1] = { cell.content_end, hidden }
      end
    end
  end

  return marks
end

local function row_cells(buf, row)
  local entry = cache[buf]
  local tick = vim.api.nvim_buf_get_changedtick(buf)
  if not entry or entry.tick ~= tick then
    entry = { tick = tick, rows = {} }
    cache[buf] = entry
  end

  local cells = entry.rows[row]
  if cells == nil then
    cells = compute_cells(buf, row)
    entry.rows[row] = cells
  end
  return cells
end

---Итоговые отступы строки: кэшированный разбор текста + живой вклад соседей
local function compute_row(buf, row)
  local cells = row_cells(buf, row)
  if not cells then
    return false
  end
  return row_padding(buf, row, cells) or false
end

---Компенсировать ли вообще. 'auto' - только если этого не делает
---render-markdown: иначе отступ добавился бы дважды
local resolved = nil

local function should_compensate()
  if config.compensate_conceal ~= 'auto' then
    return config.compensate_conceal == true
  end
  if resolved == nil then
    -- путь внутренний, поэтому под pcall; если прочитать не вышло, считаем,
    -- что таблицами никто не занимается
    local ok, state = pcall(require, 'render-markdown.state')
    local pipe_table = ok and type(state) == 'table' and type(state.config) == 'table'
      and state.config.pipe_table
    resolved = not (type(pipe_table) == 'table' and pipe_table.enabled == true)
  end
  return resolved
end

---Показывает ли редактор строку под курсором сырой (concealcursor)
local function cursor_line_raw(win)
  local mode = vim.api.nvim_get_mode().mode:sub(1, 1)
  if mode == 'V' or mode == '\22' then
    mode = 'v'
  end
  return not vim.wo[win].concealcursor:find(mode, 1, true)
end

---Работает ли компенсация в этом окне и буфере
local function active(win, buf)
  if not should_compensate() then
    return false
  end
  if vim.bo[buf].filetype ~= 'markdown' then
    return false
  end
  -- ничего не спрятано - компенсировать нечего, до treesitter не доходим
  if vim.wo[win].conceallevel == 0 then
    return false
  end
  return true
end

---Расставить отступы в диапазоне строк буфера.
---Метки ОБЫЧНЫЕ, а не ephemeral: эфемерная метка с virt_text_pos = 'inline'
---применяется нестабильно - на одной и той же строке она то отрисовывается,
---то нет (замер: 0 видимых из 14 против 14 из 14 у обычных). Это и было
---причиной "иногда таблицы ломаются"
local function apply(buf, first, last, skip_row)
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for row = first, last do
    if row ~= skip_row then
      local marks = compute_row(buf, row)
      if marks then
        for _, mark in ipairs(marks) do
          pcall(vim.api.nvim_buf_set_extmark, buf, ns, row, mark[1], {
            priority = 0,
            virt_text = { { string.rep(' ', mark[2]) } },
            virt_text_pos = 'inline',
          })
        end
      end
    end
  end
end

-- буферы, в которых сейчас стоят наши метки
local decorated = {}
-- состояние, при котором отступы уже пересчитаны: пока оно не изменилось,
-- работать заново незачем
local state = nil

local function refresh(force)
  local ranges, key = {}, {}

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if active(win, buf) then
      local info = vim.fn.getwininfo(win)[1]
      if info then
        local range = ranges[buf] or { first = math.huge, last = -1 }
        range.first = math.min(range.first, info.topline - 1)
        range.last = math.max(range.last, info.botline - 1)
        ranges[buf] = range
        key[#key + 1] = table.concat({
          win, buf, info.topline, info.botline, vim.api.nvim_buf_get_changedtick(buf),
        }, ':')
      end
    end
  end

  local win = vim.api.nvim_get_current_win()
  local cur_buf = vim.api.nvim_win_get_buf(win)
  local skip = cursor_line_raw(win) and (vim.api.nvim_win_get_cursor(win)[1] - 1) or nil
  key[#key + 1] = tostring(skip)

  local new_state = table.concat(key, '|')
  if not force and new_state == state then
    return
  end
  state = new_state

  for buf in pairs(decorated) do
    if not ranges[buf] and vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    end
  end
  decorated = {}

  for buf, range in pairs(ranges) do
    apply(buf, range.first, range.last, buf == cur_buf and skip or nil)
    decorated[buf] = true
  end
end

local scheduled, second_pass = false, false

local function schedule()
  if scheduled then
    return
  end
  scheduled = true
  vim.schedule(function()
    scheduled = false
    pcall(refresh)

    -- соседние плагины ставят свои метки с задержкой (render-markdown рисует
    -- иконку ссылки по своему таймеру), а их ширину надо вычесть из отступа.
    -- Второй проход подхватывает то, чего не было в момент первого
    if not second_pass then
      second_pass = true
      vim.defer_fn(function()
        second_pass = false
        pcall(refresh, true)
      end, 150)
    end
  end)
end

function M.setup(opts, helpers)
  config = opts
  deps = helpers
  resolved = nil
  cache = {}
  state = nil

  local group = vim.api.nvim_create_augroup('MdTableConcealCompensation', { clear = true })

  vim.api.nvim_create_autocmd({
    'BufWinEnter',
    'WinEnter',
    'WinScrolled',
    'WinResized',
    'VimResized',
    'TextChanged',
    'TextChangedI',
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

  schedule()
end

-- для тестов
M._internal = {
  compute_row = compute_row,
  ts_hidden_spans = ts_hidden_spans,
  active = active,
  refresh = refresh,
  reset_detection = function()
    resolved = nil
  end,
}

return M
