-- https://catppuccin.com/palette/
-- Rosewater   #dc8a78
-- Flamingo    #dd7878
-- Pink        #ea76cb
-- Mauve       #8839ef
-- Red         #d20f39
-- Maroon      #e64553
-- Peach       #fe640b
-- Yellow      #df8e1d
-- Green       #40a02b
-- Teal        #179299
-- Sky         #04a5e5
-- Sapphire    #209fb5
-- Blue        #1e66f5
-- Lavender    #7287fd
-- Text        #4c4f69
-- Subtext 1   #5c5f77
-- Subtext 0   #6c6f85
-- Overlay 2   #7c7f93
-- Overlay 1   #8c8fa1
-- Overlay 0   #9ca0b0
-- Surface 2   #acb0be
-- Surface 1   #bcc0cc
-- Surface 0   #ccd0da
-- Base        #eff1f5
-- Mantle      #e6e9ef
-- Crust       #dce0e8

return {
  "catppuccin/nvim",
  name = "catppuccin",
  priority = 1000,
  config = function()
    local cmd = vim.cmd
    local api = vim.api
    local fn = vim.fn

    require("catppuccin").setup({
      flavour = "auto", -- latte, frappe, macchiato, mocha
      background = { -- :h background
        light = "latte",
        dark = "frappe",
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
    api.nvim_set_hl(0, "Whitespace", { fg = "#d20f39", bg = "NONE" })

    -- Цвет колонки и строки
    api.nvim_set_hl(0, "CursorColumn", { fg = "none", bg = "#ccd0da" })
    api.nvim_set_hl(0, "CursorLine", { fg = "none", bg = "#ccd0da" })

    -- Правило подсветки для символов после 80 столбца
    api.nvim_set_hl(0, "OverLength", { fg = "#d20f39" })
    fn.matchadd("OverLength", [[\%81v.\+]])
  end,
}
