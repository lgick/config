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
