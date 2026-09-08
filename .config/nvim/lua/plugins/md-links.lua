local ns = vim.api.nvim_create_namespace('md_links_conceal')

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

-- Назначаем клавиши ОДИН РАЗ на буфер
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

local function conceal_markdown_links(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(bufnr) or vim.bo[bufnr].filetype ~= 'markdown' then
    return
  end

  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  for row_idx, line in ipairs(lines) do
    local search_start = 1
    while true do
      local s_b, s_e, label = line:find('%[([^%]]-)%]%([^%)]-%)', search_start)
      if not s_b then
        break
      end

      vim.api.nvim_buf_set_extmark(bufnr, ns, row_idx - 1, s_b - 1, { end_col = s_b, conceal = '' })
      vim.api.nvim_buf_set_extmark(
        bufnr,
        ns,
        row_idx - 1,
        s_b,
        { end_col = s_b + #label, hl_group = 'Underlined' }
      )
      vim.api.nvim_buf_set_extmark(
        bufnr,
        ns,
        row_idx - 1,
        s_b + #label,
        { end_col = s_e, conceal = '' }
      )

      search_start = s_e + 1
    end
  end
end

-- Автокоманда для Markdown
vim.api.nvim_create_autocmd({ 'FileType', 'BufWinEnter', 'TextChanged', 'TextChangedI' }, {
  group = vim.api.nvim_create_augroup('MarkdownCleanSetup', { clear = true }),
  pattern = { '*.md', 'markdown' },
  callback = function(args)
    local bufnr = args.buf

    setup_smart_navigation(bufnr)
    conceal_markdown_links(bufnr)
  end,
})
