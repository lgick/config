local zen_bufnr = nil

require('zen-mode').setup({
  window = {
    backdrop = 0.4, -- Затемнение фона вокруг текста
    width = 87, -- Ширина окна Zen
    height = 0.95, -- Высота окна Zen
    options = {
      signcolumn = 'no', -- Отключение боковой панели знаков диагностики и Git
      number = false, -- Скрытие номеров строк
      relativenumber = false, -- Скрытие относительных номеров строк
      cursorline = false, -- Отключение подсветки текущей строки (чтобы не отвлекала)
      cursorcolumn = false, -- Отключение подсветки текущего столбца
      foldcolumn = '0', -- Отключение панели свертывания кода
      list = false, -- Отключение отображения невидимых символов (табов, пробелов)
      wrap = true, -- Обязательный перенос длинных строк
      linebreak = true, -- Перенос строго по границам слов
    },
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
