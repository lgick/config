local zen_bufnr = nil

require('zen-mode').setup({
  window = {
    backdrop = 1, -- Фон окна
    width = 80, -- Ширина окна Zen
    height = 0.95, -- Высота окна Zen
  },

  -- Срабатывает при открытии Zen mode
  on_open = function()
    zen_bufnr = vim.api.nvim_get_current_buf()

    vim.keymap.set('n', 'q', '<cmd>close<CR>', {
      buffer = zen_bufnr,
      desc = 'Exit Zen Mode',
    })
  end,

  -- Срабатывает при закрытии Zen mode
  on_close = function()
    if zen_bufnr and vim.api.nvim_buf_is_valid(zen_bufnr) then
      pcall(vim.keymap.del, 'n', 'q', { buffer = zen_bufnr })
    end

    zen_bufnr = nil
  end,
})
