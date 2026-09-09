local ibl = require('ibl')

ibl.setup({
  indent = { char = '│' },
  whitespace = { highlight = { 'Whitespace', 'NonText' } },
  scope = {
    enabled = false, -- отключение рамки и подсветки активного блока
  },
  exclude = {
    filetypes = { 'markdown' },
  },
})
