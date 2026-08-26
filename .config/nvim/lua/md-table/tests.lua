-- Тесты форматтера markdown-таблиц.
-- Запуск: nvim --headless -c "lua require('md-table.tests').run()" -c qa

local md = require('md-table')
local I = md._internal

local M = {}

local failures = {}
local passed = 0

local function fail(name, msg)
  table.insert(failures, name .. ': ' .. msg)
end

local function check(name, ok, msg)
  if ok then
    passed = passed + 1
  else
    fail(name, msg or 'проверка не прошла')
  end
end

local function eq_lines(name, got, want)
  got = got or {}
  if #got ~= #want then
    fail(name, ('строк: получено %d, ожидалось %d\n--- получено ---\n%s\n--- ожидалось ---\n%s')
      :format(#got, #want, table.concat(got, '\n'), table.concat(want, '\n')))
    return false
  end
  for i = 1, #want do
    if got[i] ~= want[i] then
      fail(name, ('строка %d:\n  получено:  [%s]\n  ожидалось: [%s]'):format(i, got[i], want[i]))
      return false
    end
  end
  passed = passed + 1
  return true
end

-- Прогон через буфер (проверяет find_table_blocks и format_buffer целиком)
local function format_lines(lines)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].filetype = 'markdown'
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  md.format_buffer(buf)
  local out = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  vim.api.nvim_buf_delete(buf, { force = true })
  return out
end

local tests = {}

-- К1: таблица внутри ограждённого блока кода не трогается
tests['К1 fenced code block'] = function()
  local input = {
    'text',
    '',
    '```markdown',
    '| a | b |',
    '| - | - |',
    '| 1 | 2 |',
    '```',
    '',
  }
  eq_lines('К1 fenced', format_lines(input), input)
end

tests['К1 tilde fence'] = function()
  local input = { '~~~text', '| a | b |', '| - | - |', '~~~' }
  eq_lines('К1 tilde fence', format_lines(input), input)
end

tests['К1 таблица после ограды форматируется'] = function()
  local out = format_lines({
    '```text',
    '| a | b |',
    '```',
    '',
    '| Key | Val |',
    '| --- | --- |',
    '| a | 1 |',
  })
  eq_lines('К1 после ограды', out, {
    '```text',
    '| a | b |',
    '```',
    '',
    '| Key | Val |',
    '| --- | --- |',
    '| a   | 1   |',
  })
end

-- К2: блок pipe-строк без разделителя - не таблица GFM
tests['К2 блок без разделителя'] = function()
  local input = { '| foo | bar |', '| baz | qux |' }
  check('К2 format_single_table', I.format_single_table(input) == nil, 'ожидался nil')
  eq_lines('К2 буфер', format_lines(input), input)

  local three = { '| foo | bar |', '| baz | qux |', '| zzz | www |' }
  eq_lines('К2 буфер 3 строки', format_lines(three), three)
end

-- В3: легитимная пустая первая ячейка в чужой таблице не склеивается
tests['В3 чужая пустая первая ячейка'] = function()
  eq_lines('В3 не склеено', format_lines({
    '| Key | Val |',
    '| --- | --- |',
    '| a | 1 |',
    '|  | 2 |',
  }), {
    '| Key | Val |',
    '| --- | --- |',
    '| a   | 1   |',
    '| ~~~ | ~~~ |',
    '|     | 2   |',
  })
end

-- В3: собственный вывод форматтера, наоборот, склеивается обратно
tests['В3 перенесённая строка склеивается'] = function()
  local wide = {
    '| Key | Value |',
    '| --- | ----- |',
    '| a | ' .. string.rep('word ', 30) .. '|',
  }
  local once = format_lines(wide)
  check('В3 строка перенеслась', #once > 3, 'ожидался перенос на несколько строк')
  eq_lines('В3 идемпотентность одной строки', format_lines(once), once)
end

-- Идемпотентность
tests['идемпотентность'] = function()
  local samples = {
    { '| Key | Val |', '| --- | --- |', '| a | 1 |', '| b | 2 |' },
    {
      '| Code | Key | Sent by | Client |',
      '| --- | --- | --- | --- |',
      '| `4000` | `staleHost` | `master/SignalingServer.js` | host signaling socket, no player UI |',
      '| `4001` | `invalidOrigin` | `master/SignalingServer.js`, `dedicated/main.js` | stays put, shows the reason |',
    },
  }
  for idx, sample in ipairs(samples) do
    local once = format_lines(sample)
    eq_lines('идемпотентность #' .. idx, format_lines(once), once)
  end
end

-- Неразрывные токены не рвутся
tests['неразрывные токены'] = function()
  local link = '[очень длинное название ссылки](https://example.com/a/b/c/d/e/f)'
  local code = '`some.very.long.identifier.that.does.not.fit`'
  local html = '<img src="https://example.com/very/long/path.png" alt="картинка">'
  local out = format_lines({
    '| Key | Value |',
    '| --- | ----- |',
    '| a | ' .. link .. ' ' .. code .. ' ' .. html .. ' |',
  })
  local joined = table.concat(out, '\n')
  for _, token in ipairs({ link, code, html }) do
    check('неразрывный токен', joined:find(token, 1, true) ~= nil, 'токен порван: ' .. token)
  end
end

-- Выравнивания сохраняются
tests['выравнивания'] = function()
  local out = format_lines({
    '| a | b | c | d |',
    '| :-- | --: | :-: | --- |',
    '| 1 | 2 | 3 | 4 |',
  })
  local sep = I.split_row(out[2])
  check('выравнивание left', sep[1]:sub(1, 1) == ':' and sep[1]:sub(-1, -1) ~= ':', sep[1])
  check('выравнивание right', sep[2]:sub(1, 1) ~= ':' and sep[2]:sub(-1, -1) == ':', sep[2])
  check('выравнивание center', sep[3]:sub(1, 1) == ':' and sep[3]:sub(-1, -1) == ':', sep[3])
  check('выравнивание default', sep[4]:match('^%-+$') ~= nil, sep[4])
end

-- Ширина считается по strdisplaywidth, а не по байтам
tests['кириллица и эмодзи'] = function()
  local out = format_lines({
    '| Ключ | Значение |',
    '| --- | --- |',
    '| привет | мир |',
    '| ok | 🎉 |',
  })
  local first = I.display_width(out[1])
  for i, line in ipairs(out) do
    check('одинаковая ширина строки ' .. i, I.display_width(line) == first,
      ('строка %d: %d вместо %d [%s]'):format(i, I.display_width(line), first, line))
  end
end

-- Экранированная труба не создаёт лишних колонок и занимает одну колонку ширины
tests['экранированные трубы'] = function()
  local out = format_lines({
    '| Key | Value |',
    '| --- | ----- |',
    [[| a | x \| y |]],
  })
  for i, line in ipairs(out) do
    check('число колонок в строке ' .. i, #I.split_row(line) == 2, line)
  end
  local first = I.display_width(out[1])
  for i, line in ipairs(out) do
    check('ширина строки ' .. i, I.display_width(line) == first,
      ('строка %d: %d вместо %d [%s]'):format(i, I.display_width(line), first, line))
  end
end

-- С3: calculate_target_widths не отдаёт наружу свой вход
tests['С3 без алиасинга'] = function()
  local natural = { 10, 10 }
  local target = I.calculate_target_widths(natural, { 3, 3 }, 100)
  target[1] = 999
  check('С3 natural не мутирован', natural[1] == 10, 'natural_widths изменился')
end

-- С4: токен из одних маркеров не даёт нулевую ширину
tests['С4 короткие маркеры'] = function()
  local prev = I.display_width
  I.set_config({ ignore_markdown_syntax = true })
  for _, token in ipairs({ '**', '__', '~~' }) do
    check('С4 ширина ' .. token, I.display_width(token) == 2,
      token .. ' измерен как ' .. I.display_width(token))
  end
  I.set_config({})
  check('С4 конфиг восстановлен', prev ~= nil, '')
end

-- ── Компенсация conceal ──────────────────────────────────────────────────

local conceal = require('md-table.conceal')

local function mk_buf(lines)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].filetype = 'markdown'
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  return buf
end

local function paddings(buf, row)
  local total = 0
  for _, mark in ipairs(conceal._internal.compute_row(buf, row) or {}) do
    total = total + mark[2]
  end
  return total
end

-- Видимая ширина строки: сырая минус скрытое плюс компенсация
local function visible_width(buf, row)
  local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1] or ''
  local hidden = 0
  for _, span in ipairs(conceal._internal.ts_hidden_spans(buf, row) or {}) do
    hidden = hidden + span[3]
  end
  return vim.fn.strdisplaywidth(line) - hidden + paddings(buf, row)
end

tests['conceal: ширина отступов'] = function()
  local buf = mk_buf({
    '| Key | Value            |',
    '| --- | ---------------- |',
    '| a   | **жирный** `x`   |',
    '| ~~~ | ~~~~~~~~~~~~~~~~ |',
    '| b   | [link](u) x \\| y |',
  })
  check('conceal шапка', paddings(buf, 0) == 0, tostring(paddings(buf, 0)))
  check('conceal разделитель', paddings(buf, 1) == 0, tostring(paddings(buf, 1)))
  check('conceal ** и ` = 6', paddings(buf, 2) == 6, tostring(paddings(buf, 2)))
  check('conceal строка-линия = 0', paddings(buf, 3) == 0, tostring(paddings(buf, 3)))
  -- скрыт синтаксис ссылки (5 колонок), но НЕ слэш из \|
  check('conceal ссылка = 5, экранирование не в счёт', paddings(buf, 4) == 5,
    tostring(paddings(buf, 4)))
  vim.api.nvim_buf_delete(buf, { force = true })
end

tests['conceal: сторона отступа'] = function()
  local right = mk_buf({
    '| Key |    Value |',
    '| --- | -------: |',
    '| a   | **жир**  |',
  })
  local marks = conceal._internal.compute_row(right, 2) or {}
  check('conceal вправо: один отступ слева', #marks == 1, '#marks=' .. #marks)
  vim.api.nvim_buf_delete(right, { force = true })

  local center = mk_buf({
    '| Key |   Value   |',
    '| --- | :-------: |',
    '| a   |  **жир**  |',
  })
  marks = conceal._internal.compute_row(center, 2) or {}
  local total = 0
  for _, m in ipairs(marks) do total = total + m[2] end
  check('conceal по центру: делится пополам', #marks == 2 and total == 4,
    ('#marks=%d total=%d'):format(#marks, total))
  vim.api.nvim_buf_delete(center, { force = true })
end

tests['conceal: фолбэк без парсера'] = function()
  local buf = mk_buf({
    '| Key | Value      |',
    '| --- | ---------- |',
    '| a   | **жирный** |',
  })
  local original = vim.treesitter.get_parser
  vim.treesitter.get_parser = function()
    error('нет парсера')
  end
  local ok, pad = pcall(paddings, buf, 2)
  vim.treesitter.get_parser = original
  check('conceal фолбэк не падает', ok, tostring(pad))
  check('conceal фолбэк считает ширину', ok and pad == 4, tostring(pad))
  vim.api.nvim_buf_delete(buf, { force = true })
end

tests['conceal: видимая ширина выровнена'] = function()
  local raw = {
    '| Key | Value |',
    '| --- | ----- |',
    '| `a` | **жирный** текст |',
    '| b | [ссылка](https://example.com) |',
    '| c | x \\| y |',
    '| d | обычный текст |',
  }
  local buf = mk_buf(raw)
  md.format_buffer(buf)
  local n = vim.api.nvim_buf_line_count(buf)
  local widths = {}
  for row = 0, n - 1 do
    local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1] or ''
    if line:sub(1, 1) == '|' then
      widths[#widths + 1] = visible_width(buf, row)
    end
  end
  local mn, mx = math.huge, 0
  for _, w in ipairs(widths) do mn = math.min(mn, w); mx = math.max(mx, w) end
  check('conceal разброс видимой ширины = 0', mx - mn == 0,
    ('разброс=%d (%d..%d) строк=%d'):format(mx - mn, mn, mx, #widths))
  vim.api.nvim_buf_delete(buf, { force = true })
end

tests['conceal: условия включения'] = function()
  local buf = mk_buf({ '| a | b |', '| --- | --- |' })
  local win = vim.api.nvim_get_current_win()
  local prev_ft = vim.bo[vim.api.nvim_win_get_buf(win)].filetype
  local prev_cl = vim.wo[win].conceallevel

  -- отвязываемся от живой настройки render-markdown: она может быть любой
  local saved = package.loaded['render-markdown.state']
  package.loaded['render-markdown.state'] = { config = { pipe_table = { enabled = false } } }
  conceal._internal.reset_detection()

  vim.wo[win].conceallevel = 2
  check('conceal включён при conceallevel=2', conceal._internal.active(win, buf) == true)

  vim.wo[win].conceallevel = 0
  check('conceal выключен при conceallevel=0', conceal._internal.active(win, buf) == false)

  vim.wo[win].conceallevel = 2
  local other = vim.api.nvim_create_buf(false, true)
  vim.bo[other].filetype = 'text'
  check('conceal выключен вне markdown', conceal._internal.active(win, other) == false)
  vim.api.nvim_buf_delete(other, { force = true })

  -- 'auto': если таблицами занимается render-markdown, компенсации быть не должно
  package.loaded['render-markdown.state'] = { config = { pipe_table = { enabled = true } } }
  conceal._internal.reset_detection()
  check('conceal auto: render-markdown уже padded -> выключено',
    conceal._internal.active(win, buf) == false)

  package.loaded['render-markdown.state'] = { config = { pipe_table = { enabled = false } } }
  conceal._internal.reset_detection()
  check('conceal auto: pipe_table выключен -> включено',
    conceal._internal.active(win, buf) == true)

  package.loaded['render-markdown.state'] = saved
  conceal._internal.reset_detection()
  vim.wo[win].conceallevel = prev_cl
  vim.bo[vim.api.nvim_win_get_buf(win)].filetype = prev_ft
  vim.api.nvim_buf_delete(buf, { force = true })
end

-- Регресс на найденную причину «иногда таблицы ломаются»: метки должны быть
-- ОБЫЧНЫМИ. Эфемерная метка с virt_text_pos = 'inline' применяется нестабильно
-- (замер на живом экране: 0 видимых из 14 против 14 из 14 у обычных), а
-- эфемерных меток nvim_buf_get_extmarks не возвращает вовсе
tests['conceal: метки не эфемерные'] = function()
  local win = vim.api.nvim_get_current_win()
  local prev_cl = vim.wo[win].conceallevel
  local saved = package.loaded['render-markdown.state']
  package.loaded['render-markdown.state'] = { config = { pipe_table = { enabled = false } } }
  conceal._internal.reset_detection()
  vim.wo[win].conceallevel = 2

  local buf = mk_buf({
    '| Key | Value          |',
    '| --- | -------------- |',
    '| a   | **жирный** `x` |',
  })
  vim.api.nvim_win_set_buf(win, buf)
  conceal._internal.refresh(true)

  local ns = vim.api.nvim_create_namespace('md_table_conceal')
  local marks = vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, { details = true })
  check('conceal метки поставлены', #marks > 0, '#marks=' .. #marks)

  local total, inline = 0, 0
  for _, m in ipairs(marks) do
    if m[4] and m[4].virt_text_pos == 'inline' then
      inline = inline + 1
      for _, chunk in ipairs(m[4].virt_text) do
        total = total + vim.fn.strdisplaywidth(chunk[1])
      end
    end
  end
  check('conceal метки inline', inline == #marks, inline .. '/' .. #marks)
  check('conceal суммарный отступ = 6', total == 6, tostring(total))

  package.loaded['render-markdown.state'] = saved
  conceal._internal.reset_detection()
  vim.wo[win].conceallevel = prev_cl
end

-- Регресс на вторую причину: соседний плагин не только прячет, но и дорисовывает
-- (render-markdown ставит иконку ссылки шириной 2 колонки). Эту ширину надо
-- вычесть из отступа, иначе строка со ссылкой выезжает вправо
tests['conceal: чужой inline virt_text вычитается'] = function()
  local buf = mk_buf({
    '| Key | Value         |',
    '| --- | ------------- |',
    '| a   | [link](u) тут |',
  })
  local before = paddings(buf, 2)
  check('conceal ссылка без соседей', before == 5, tostring(before))

  local foreign = vim.api.nvim_create_namespace('md_table_test_foreign')
  local line = vim.api.nvim_buf_get_lines(buf, 2, 3, false)[1]
  vim.api.nvim_buf_set_extmark(buf, foreign, 2, line:find('%[') - 1, {
    virt_text = { { '󰌹 ' } },
    virt_text_pos = 'inline',
  })
  local after = paddings(buf, 2)
  check('conceal иконка соседа вычтена', after == before - 2,
    ('было %d, стало %d'):format(before, after))
  vim.api.nvim_buf_delete(buf, { force = true })
end

function M.run()
  local names = vim.tbl_keys(tests)
  table.sort(names)
  for _, name in ipairs(names) do
    local ok, err = pcall(tests[name])
    if not ok then
      fail(name, 'исключение: ' .. tostring(err))
    end
  end

  if #failures == 0 then
    print(('ВСЕ ТЕСТЫ ПРОЙДЕНЫ (%d проверок)'):format(passed))
    return true
  end

  print(('ПРОВАЛЕНО: %d, пройдено: %d'):format(#failures, passed))
  for _, f in ipairs(failures) do
    print('  ✗ ' .. f)
  end
  return false
end

return M
