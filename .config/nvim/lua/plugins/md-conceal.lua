local ns = vim.api.nvim_create_namespace('md_conceal')

-- Поиск скрытых зон для быстрого перемещения
local function get_concealed_ranges(row)
  local marks = vim.api.nvim_buf_get_extmarks(0, ns, { row, 0 }, { row, -1 }, { details = true })
  local ranges = {}
  for _, m in ipairs(marks) do
    local d = m[4]
    if d and d.conceal == '' and d.end_col then
      table.insert(ranges, { start_col = m[3], end_col = d.end_col })
    end
  end
  return ranges
end

-- Быстрая навигация без залипаний на h, l, w, b
local function setup_smart_navigation(bufnr)
  if vim.b[bufnr].md_nav_setup then
    return
  end
  vim.b[bufnr].md_nav_setup = true

  local opts = { buffer = bufnr, silent = true, noremap = true }

  local function move_right()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local row, col = cursor[1] - 1, cursor[2]
    vim.cmd('normal! l')
    local new_col = vim.api.nvim_win_get_cursor(0)[2]
    for _, r in ipairs(get_concealed_ranges(row)) do
      if new_col >= r.start_col and new_col < r.end_col then
        vim.api.nvim_win_set_cursor(0, { row + 1, r.end_col })
        break
      end
    end
  end

  local function move_left()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local row, col = cursor[1] - 1, cursor[2]
    if col == 0 then
      vim.cmd('normal! h')
      return
    end
    vim.cmd('normal! h')
    local new_col = vim.api.nvim_win_get_cursor(0)[2]
    for _, r in ipairs(get_concealed_ranges(row)) do
      if new_col >= r.start_col and new_col < r.end_col then
        vim.api.nvim_win_set_cursor(0, { row + 1, r.start_col })
        if r.start_col > 0 then
          vim.cmd('normal! h')
        end
        break
      end
    end
  end

  local function move_word_forward()
    vim.cmd('normal! w')
    local cursor = vim.api.nvim_win_get_cursor(0)
    local row, col = cursor[1] - 1, cursor[2]
    for _, r in ipairs(get_concealed_ranges(row)) do
      if col >= r.start_col and col < r.end_col then
        vim.api.nvim_win_set_cursor(0, { row + 1, r.end_col })
        break
      end
    end
  end

  local function move_word_backward()
    vim.cmd('normal! b')
    local cursor = vim.api.nvim_win_get_cursor(0)
    local row, col = cursor[1] - 1, cursor[2]
    for _, r in ipairs(get_concealed_ranges(row)) do
      if col >= r.start_col and col < r.end_col then
        vim.api.nvim_win_set_cursor(0, { row + 1, r.start_col })
        if r.start_col > 0 then
          vim.cmd('normal! h')
        end
        break
      end
    end
  end

  vim.keymap.set({ 'n', 'v' }, 'l', move_right, opts)
  vim.keymap.set({ 'n', 'v' }, '<Right>', move_right, opts)
  vim.keymap.set({ 'n', 'v' }, 'h', move_left, opts)
  vim.keymap.set({ 'n', 'v' }, '<Left>', move_left, opts)
  vim.keymap.set({ 'n', 'v' }, 'w', move_word_forward, opts)
  vim.keymap.set({ 'n', 'v' }, 'b', move_word_backward, opts)
end

-- Скрытие всех синтаксических спецсимволов Markdown
local function conceal_markdown_syntax(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(bufnr) or vim.bo[bufnr].filetype ~= 'markdown' then
    return
  end

  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  for row_idx, line in ipairs(lines) do
    local r = row_idx - 1

    -- 1. Ссылки: скрываем только '[' и '](url)'
    local s = 1
    while true do
      local s_b, s_e, label = line:find('%[([^%]]-)%]%([^%)]-%)', s)
      if not s_b then
        break
      end
      vim.api.nvim_buf_set_extmark(bufnr, ns, r, s_b - 1, { end_col = s_b, conceal = '' })
      vim.api.nvim_buf_set_extmark(bufnr, ns, r, s_b + #label, { end_col = s_e, conceal = '' })
      s = s_e + 1
    end

    -- 2. Инлайн-код: скрываем только `
    s = 1
    while true do
      local s_b, s_e = line:find('`([^`]+)`', s)
      if not s_b then
        break
      end
      vim.api.nvim_buf_set_extmark(bufnr, ns, r, s_b - 1, { end_col = s_b, conceal = '' })
      vim.api.nvim_buf_set_extmark(bufnr, ns, r, s_e - 1, { end_col = s_e, conceal = '' })
      s = s_e + 1
    end

    -- 3. Жирный: скрываем только **
    s = 1
    while true do
      local s_b, s_e = line:find('%*%*([^%*]+)%*%*', s)
      if not s_b then
        break
      end
      vim.api.nvim_buf_set_extmark(bufnr, ns, r, s_b - 1, { end_col = s_b + 1, conceal = '' })
      vim.api.nvim_buf_set_extmark(bufnr, ns, r, s_e - 2, { end_col = s_e, conceal = '' })
      s = s_e + 1
    end

    -- 4. Зачёркнутый: скрываем только ~~
    s = 1
    while true do
      local s_b, s_e = line:find('~~([^~]+)~~', s)
      if not s_b then
        break
      end
      vim.api.nvim_buf_set_extmark(bufnr, ns, r, s_b - 1, { end_col = s_b + 1, conceal = '' })
      vim.api.nvim_buf_set_extmark(bufnr, ns, r, s_e - 2, { end_col = s_e, conceal = '' })
      s = s_e + 1
    end
  end
end

-- Автокоманда для Markdown
vim.api.nvim_create_autocmd({ 'FileType', 'BufWinEnter', 'TextChanged', 'TextChangedI' }, {
  group = vim.api.nvim_create_augroup('MarkdownCleanSetup', { clear = true }),
  pattern = { '*.md', 'markdown' },
  callback = function(args)
    local bufnr = args.buf

    -- Переносы и отступы
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
    vim.opt_local.breakindent = true
    vim.opt_local.breakindentopt = 'shift:2'
    vim.opt_local.statuscolumn = '   '
    vim.opt_local.list = false
    vim.opt_local.cursorline = false

    -- Скрытие символов:
    vim.opt_local.conceallevel = 2
    vim.opt_local.concealcursor = 'nc' -- В Normal скрыто, в Insert открывается на текущей строке

    setup_smart_navigation(bufnr)
    conceal_markdown_syntax(bufnr)
  end,
})

-- Раскомментировать, чтобы в Insert mode раскрывался ВЕСЬ ФАЙЛ сразу (а не только текущая строка)
--vim.api.nvim_create_autocmd('InsertEnter', {
--  pattern = { '*.md', 'markdown' },
--  callback = function()
--    vim.opt_local.conceallevel = 0
--    vim.opt_local.cursorline = true
--  end,
--})
--vim.api.nvim_create_autocmd('InsertLeave', {
--  pattern = { '*.md', 'markdown' },
--  callback = function()
--    vim.opt_local.conceallevel = 2
--    vim.opt_local.cursorline = false
--  end,
--})
