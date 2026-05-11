local M = {}

local api = vim.api
local fn = vim.fn
local cmd = vim.cmd

-- Функция создания команд подтверждения
function M.create_confirm_command(opts)
  api.nvim_create_user_command(opts.name, function()
    local ok, answer = pcall(fn.input, opts.prompt)

    cmd('redraw!')
    api.nvim_echo({}, false, {})

    if ok and type(answer) == 'string' and answer:lower() == 'y' then
      vim.schedule(opts.action)
    end
  end, {
    desc = opts.desc,
  })
end

return M
