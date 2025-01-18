local g = vim.g
local opt = vim.opt
local map = vim.keymap.set

-- <C-o> - переход на предыдущую позицию в списке переходов
-- <C-i> - переход на следующую позицию в списке переходов
-- :ju - лист переходов
-- gc - комментарий в visual mode
-- <C-f> - command history window

g.mapleader = ","

------------------------------------------
-- Форматирование текста
------------------------------------------

-- Переключение языка в режиме ввода
map("i", "<C-l>", "<C-^>")

-- Сброс языка при выходе из Insert mode
map("i", "<ESC>", "<ESC><cmd>set iminsert=0<CR>")

-- Переключение языка в режиме поиска
map("c", "<C-l>", "<C-^>")

------------------------------------------
-- Hardcore mode
------------------------------------------

-- Отключение стрелочек
map("n", "<Up>", "<nop>")
map("n", "<Down>", "<nop>")
map("n", "<Left>", "<nop>")
map("n", "<Right>", "<nop>")
map("i", "<BS>", "<nop>")

----------------------------------------
-- Hotkeys
----------------------------------------

-- , + p: Открывает предыдущий буфер
map("n", "<leader>p", "<cmd>bp<CR>")

-- , + n: Открывает следующий буфер
map("n", "<leader>n", "<cmd>bn<CR>")

-- , + d: Удаляет буфер
map("n", "<leader>d", "<cmd>bdel<CR>")

-- , + c: Копирует в системный буфер
map("v", "<leader>c", '"+y')

-- , + v: Вставляет из системного буфера
map("n", "<leader>v", '"+p')

-- , + f: File Explorer
map("n", "<leader>f", "<cmd>NvimTreeToggle<CR>")

-- , + w: Git blame
map("n", "<leader>w", "<cmd>BlameToggle<CR>")

-- , + l: Подсвечивает координаты курсора
local cursorLight = false
map("n", "<leader>l", function()
  if cursorLight == true then
    opt.cursorline = false
    opt.cursorcolumn = false
    cursorLight = false
  else
    opt.cursorline = true
    opt.cursorcolumn = true
    cursorLight = true
  end
end)

-- , + z: Сворачивает функциональные блоки в файле
map("n", "<leader>z", function()
  local cmd = vim.cmd
  local api = vim.api
  local fn = vim.fn

  -- Проверяем, существует ли переменная vim.b.space
  if fn.exists("b:space") == 0 then
    api.nvim_buf_set_var(0, "space", 0)
  end

  -- Сворачиваем все блоки
  api.nvim_command("normal zE")

  -- Спрашиваем уровень отступа
  local i = 0
  local lenline = fn.line("$")
  local currentline = fn.line(".")
  cmd("call inputsave()")
  local space = fn.input("how many space (current value: " .. api.nvim_buf_get_var(0, "space") .. ")? ")
  cmd("call inputrestore()")

  -- Обновляем значение vim.b.space, если пользователь ввел новое значение
  local num_space = tonumber(space)
  if num_space ~= nil then
    api.nvim_buf_set_var(0, "space", num_space)
  end

  -- значение умножаем на tabstop
  local tabstop = tonumber(vim.opt.tabstop:get()) or 2
  local indent = api.nvim_buf_get_var(0, "space") * tabstop

  -- Сворачиваем блоки с уровнем отступа, равным vim.b.space
  while i <= lenline do
    local str = fn.getline(i)
    if fn.indent(i) == indent then
      if fn.match(str, "[{(%[]") ~= -1 then
        api.nvim_win_set_cursor(0, { i, 0 })
        api.nvim_command("normal $zf%")
      end
    end
    i = i + 1
  end

  -- Возвращаемся к текущей строке
  api.nvim_win_set_cursor(0, { currentline, 0 })
  api.nvim_command("echo ''")
end)

----------------------------------------
-- Telescope
----------------------------------------

-- поиск файлов
map("n", "<leader>s", "<cmd>Telescope find_files<CR>")

-- поиск по файлам
map("n", "<leader>g", "<cmd>Telescope live_grep<CR>")

-- буфферы
map("n", "<leader>b", "<cmd>Telescope buffers<CR>")

-- Show LSP references
map("n", "<leader>a", "<cmd>Telescope lsp_references<CR>")

-- Show LSP implementations
map("n", "<leader>o", "<cmd>Telescope lsp_implementations jump_type=split<CR>")

----------------------------------------
-- Trouble
----------------------------------------

-- Open trouble workspace diagnostics
map("n", "<leader>x", "<cmd>Trouble diagnostics toggle<CR>")

-- Open trouble document diagnostics
map("n", "<leader>X", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>")

----------------------------------------
-- LSP
----------------------------------------

-- Toggle diagnostic
map("n", "<leader>t", function()
  vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end)

-- See available code actions
map({ "n", "v" }, "<leader>m", vim.lsp.buf.code_action)

-- Изменить название в файле
map("n", "<leader>r", vim.lsp.buf.rename)

-- Show documentation for what is under cursor
map("n", "<leader>i", vim.lsp.buf.hover)

------------------------------------------
-- Cmp
------------------------------------------

-- Показывает доступные fields
map("i", "<C-n>", function()
  local cmp = require("cmp")

  if not cmp.visible() then
    local buf_clients = vim.lsp.get_clients({ bufnr = 0 })
    local type = ""

    for _, client in pairs(buf_clients) do
      if client.name == "tsserver" then
        type = "Field"
        --elseif client.name == "lua_ls" then
        --  type = "Property"
      end
    end

    cmp.complete({
      config = {
        sources = {
          {
            name = "nvim_lsp",
            entry_filter = function(entry)
              if type ~= "" then
                return require("cmp.types").lsp.CompletionItemKind[entry:get_kind()] == type
              end
              return true
            end,
          },
        },
      },
    })
  end
end)

------------------------------------------
-- Codeium
------------------------------------------

-- Открывает чат
map("n", "<leader>h", "<cmd>call codeium#Chat()<CR>")
