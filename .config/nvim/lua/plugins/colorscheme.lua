-- rosewater = "#f2d5cf",
-- flamingo = "#eebebe",
-- pink = "#f4b8e4",
-- mauve = "#ca9ee6",
-- red = "#e78284",
-- maroon = "#ea999c",
-- peach = "#ef9f76",
-- yellow = "#e5c890",
-- green = "#a6d189",
-- teal = "#81c8be",
-- sky = "#99d1db",
-- sapphire = "#85c1dc",
-- blue = "#8caaee",
-- lavender = "#babbf1",
-- text = "#c6d0f5",
-- subtext1 = "#b5bfe2",
-- subtext0 = "#a5adce",
-- overlay2 = "#949cbb",
-- overlay1 = "#838ba7",
-- overlay0 = "#737994",
-- surface2 = "#626880",
-- surface1 = "#51576d",
-- surface0 = "#414559",
-- base = "#303446",
-- mantle = "#292c3c",
-- crust = "#232634",

return {
  "catppuccin/nvim",
  name = "catppuccin",
  priority = 1000,
  config = function()
    local cmd = vim.cmd
    local api = vim.api
    local fn = vim.fn

    require("catppuccin").setup({
      flavour = "frappe", -- latte, frappe, macchiato, mocha, auto
      background = { -- :h background
        light = "latte",
        dark = "mocha",
      },
      transparent_background = false, -- disables setting the background color.
      show_end_of_buffer = false, -- shows the '~' characters after the end of buffers
      term_colors = false, -- sets terminal colors (e.g. `g:terminal_color_0`)
      dim_inactive = {
        enabled = false, -- dims the background color of inactive window
        shade = "dark",
        percentage = 0.15, -- percentage of the shade to apply to the inactive window
      },
      no_italic = false, -- Force no italic
      no_bold = false, -- Force no bold
      no_underline = false, -- Force no underline
      styles = { -- Handles the styles of general hi groups (see `:h highlight-args`):
        comments = { "italic" }, -- Change the style of comments
        conditionals = { "italic" },
        loops = {},
        functions = {},
        keywords = {},
        strings = {},
        variables = {},
        numbers = {},
        booleans = {},
        properties = {},
        types = {},
        operators = {},
        -- miscs = {}, -- Uncomment to turn off hard-coded styles
      },
      color_overrides = {},
      custom_highlights = {},
      default_integrations = true,
      integrations = {
        cmp = true,
        gitsigns = true,
        nvimtree = true,
        treesitter = true,
        notify = false,
        mini = {
          enabled = true,
          indentscope_color = "",
        },
        -- For more plugins integrations please scroll down (https://github.com/catppuccin/nvim#integrations)
      },
    })

    cmd("colorscheme catppuccin")

    -- Цвет невидимых символов listchars
    api.nvim_set_hl(0, "Whitespace", { fg = "#AF0000", bg = "NONE" })

    -- Цвет колонки
    api.nvim_set_hl(0, "CursorColumn", { fg = "none", bg = "#3b3f52" })

    -- Правило подсветки для символов после 80 столбца
    api.nvim_set_hl(0, "OverLength", { fg = "#626880" })
    fn.matchadd("OverLength", [[\%81v.\+]])
  end,
}
