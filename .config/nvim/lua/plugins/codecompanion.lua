-- Переменная для хранения ID и состояния нашего сервера
local server_job = {
  id = nil,
  ready = false, -- Флаг, что сервер готов
}

-- Команда для запуска сервера
local server_command = {
  'llama-server',
  '-hf',
  'ggml-org/gemma-4-E4B-it-GGUF',
  '-c',
  '100000',
  '--port',
  '8080',
}

-- Создаем автокоманды
local augroup = vim.api.nvim_create_augroup('LlamaServerManager', { clear = true })

-- Автокоманда для ЗАПУСКА
vim.api.nvim_create_autocmd('VimEnter', {
  group = augroup,
  pattern = '*',
  callback = function()
    local check_port = io.popen('lsof -i :8080')

    if not check_port then
      vim.notify('🔥 Не удалось проверить порт 8080', vim.log.levels.ERROR)
      return
    end

    if check_port:read('*a') == '' then
      vim.notify(
        '🚀 Запускаю локальный llama-server... Ожидайте, модель загружается.',
        vim.log.levels.INFO
      )

      -- Запускаем сервер с колбэками для отслеживания его состояния
      server_job.id = vim.fn.jobstart(server_command, {
        -- Эта функция будет вызываться каждый раз, когда сервер что-то пишет в консоль
        on_stdout = function(_, data, _)
          -- data приходит в виде таблицы строк, соединяем их
          local output_line = table.concat(data, '')
          -- Ищем ключевую фразу и проверяем, что мы еще не показывали уведомление
          if not server_job.ready and string.find(output_line, 'server listening on') then
            server_job.ready = true -- Устанавливаем флаг
            vim.schedule(
              function() -- vim.schedule нужен для безопасного вызова notify из колбэка
                vim.notify('✅ llama-server готов к работе!', vim.log.levels.INFO)
              end
            )
          end
        end,

        -- Очень полезно: если сервер упадет с ошибкой, мы увидим ее
        on_stderr = function(_, data, _)
          local error_line = table.concat(data, '')

          -- Пропускаем пустые строки
          if error_line == '' then
            return
          end

          -- 1. Игнорируем строки, содержащие стандартные маркеры логов ( I ) и ( W ) в любом месте
          if string.find(error_line, ' I ') or string.find(error_line, ' W ') then
            return
          end

          -- 2. Игнорируем строки инициализации «железа», которые могут идти без маркеров времени
          if
            string.find(error_line, 'BLAS')
            or string.find(error_line, 'MTL')
            or string.find(error_line, 'CPU')
            or string.find(error_line, 'system_info')
          then
            return
          end

          -- Показываем только реальные критические ошибки (например, содержащие ' E ' или 'error')
          vim.schedule(function()
            vim.notify('🔥 llama-server: ' .. error_line, vim.log.levels.ERROR)
          end)
        end,

        -- Сообщим, если процесс завершился сам по себе
        on_exit = function(_, code, _)
          if code ~= 0 then -- Если код выхода не 0 (успех)
            vim.schedule(function()
              vim.notify(
                '⚠️ llama-server неожиданно завершился. Код: '
                  .. tostring(code),
                vim.log.levels.WARN
              )
            end)
          end
        end,
      })
    else
      server_job.ready = true -- Если порт занят, считаем что сервер уже готов
      vim.notify('✅ llama-server уже запущен.', vim.log.levels.INFO)
    end
    check_port:close()
  end,
})

-- Автокоманда для ОСТАНОВКИ
vim.api.nvim_create_autocmd('VimLeavePre', {
  group = augroup,
  pattern = '*',
  callback = function()
    if server_job.id and server_job.id > 0 then
      vim.notify(
        '🛑 Останавливаю локальный llama-server...',
        vim.log.levels.INFO
      )
      vim.fn.jobstop(server_job.id)
      server_job.id = nil
      server_job.ready = false
    end
  end,
})

require('codecompanion').setup({
  adapters = {
    http = {
      ['llama.cpp'] = function()
        return require('codecompanion.adapters').extend('openai_compatible', {
          env = {
            url = 'http://127.0.0.1:8080',
            api_key = 'TERM',
            chat_url = '/v1/chat/completions',
          },
          handlers = {
            parse_message_meta = function(_, data)
              local extra = data.extra
              if extra and extra.reasoning_content then
                data.output.reasoning = { content = extra.reasoning_content }
                if data.output.content == '' then
                  data.output.content = nil
                end
              end
              return data
            end,
          },
        })
      end,
    },
  },
  interactions = {
    chat = {
      adapter = 'llama.cpp',
      opts = {
        system_prompt = function(ctx)
          local custom_instructions = [[
1. Язык: Всегда отвечай исключительно на русском языке. Код и комментарии в коде на английском.
2. Краткость: Будь лаконичен. Избегай длинных приветствий, вежливых вступлений и заключений. Сразу переходи к делу.
3. Качество кода: пиши чистый, современный код с обработкой ошибок. Не используй устаревшие практики. Не используй лишних символов (номерация строк, разделители), используй только пробелы.
4. Контекст: твоя среда разработки — neovim. Если контекст вопроса касается редактора, пиши современный Lua-код с использованием vim.api и встроенных функций.
]]
          return ctx.default_system_prompt .. '\n\n' .. custom_instructions
        end,
      },
    },
    inline = {
      adapter = 'llama.cpp',
    },
  },
})
