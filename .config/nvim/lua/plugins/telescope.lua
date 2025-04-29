return {
  "nvim-telescope/telescope.nvim",
  branch = "0.1.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    "nvim-tree/nvim-web-devicons",
    "folke/todo-comments.nvim",
  },
  config = function()
    local telescope = require("telescope")
    local actions = require("telescope.actions")

    -- Функция для создания записи, отображающей только путь, без лишней информации
    local custom_grep_entry_maker = function(entry)
      local filename, lnum, col, text = entry:match("^(.-):(%d+):(%d+):(.*)$")

      if filename then
        return {
          value = filename,
          display = filename .. ":" .. lnum, -- Формируем строку "путь:строка"
          ordinal = filename, -- Сортируем по имени файла
          filename = filename,
          lnum = tonumber(lnum), -- Преобразуем в число
          col = tonumber(col), -- Преобразуем в число
          text = text, -- Сохраняем текст совпадения для превью
        }
      else
        -- Если строка не соответствует формату отображаем ее как есть.
        return {
          value = entry,
          display = entry,
          ordinal = entry,
        }
      end
    end

    telescope.setup({
      pickers = {
        live_grep = {
          entry_maker = custom_grep_entry_maker,
        },
        buffers = {
          show_all_buffers = true,
          sort_lastused = true,
          file_ignore_patterns = {},
          ignore_current_buffer = true,
          theme = "dropdown",
          previewer = false,
          mappings = {
            i = {
              ["<C-d>"] = actions.delete_buffer + actions.move_to_top,
            },
          },
        },
      },
      defaults = {
        layout_strategy = "horizontal", -- или 'flex'
        layout_config = {
          -- ширина и высота окна Telescope
          -- Например, 90% ширины экрана
          width = 0.9,
          height = 0.9,

          -- ширина предпросмотра
          -- Можно также указать абсолютное количество колонок (менее гибко):
          -- preview_width = 100,
          preview_width = 0.6,

          -- prompt_position = "top", -- Расположение строки ввода
          -- mirror = false, -- false: предпросмотр справа (по умолчанию), true: слева
        },
        default_mappings = {},
        file_ignore_patterns = {
          "%.svg",
          "%.gif",
          "%.jpeg",
          "%.jpg",
          "%.png",
          "%.webp",
          "%.ico",
          "%.ttf",
          "%.git/",
          "dist/",
          "build/",
          "node_modules/",
          "package%-lock%.json",
        },
        vimgrep_arguments = {
          "rg",
          "--color=never",
          "--no-heading",
          "--with-filename",
          "--line-number",
          "--column",
          "--hidden",
          "--smart-case",
        },
        path_display = { "absolute" },
        mappings = {
          i = {
            ["<C-k>"] = actions.move_selection_previous,
            ["<C-j>"] = actions.move_selection_next,
            ["<C-p>"] = actions.preview_scrolling_up,
            ["<C-n>"] = actions.preview_scrolling_down,
            ["<C-u>"] = actions.move_to_top,
            ["<C-d>"] = actions.move_to_bottom,
            ["<C-s>"] = actions.select_vertical,
            ["<C-i>"] = actions.select_horizontal,
            ["<C-o>"] = actions.send_to_qflist + actions.open_qflist,
            ["<ESC>"] = actions.close,
            ["<CR>"] = actions.select_default,
          },
          n = {
            ["<ESC>"] = actions.close,
          },
        },
      },
    })

    telescope.load_extension("fzf")
  end,
}
