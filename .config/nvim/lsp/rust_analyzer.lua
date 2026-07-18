return {
  settings = {
    ['rust-analyzer'] = {
      cargo = {
        buildScripts = {
          enable = true, --генерация кода внутри макросов (например, в tokio, serde)
        },
      },
      procMacro = {
        enable = true, -- поддержка процедурных макросов
      },
      checkOnSave = true,
      check = {
        command = 'clippy', -- более строгий clippy при сохранении
      },
    },
  },
}
