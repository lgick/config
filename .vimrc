" Плагины VIM:
" ----------------------------------------

set nocompatible
filetype off

call plug#begin('~/.vim/plugged')

" Nerdtree: навигация по файлам
Plug 'scrooloose/nerdtree'
set wildignore+=*.pyc,*.o,*.obj,*.svn,*.swp,*.class,*.hg,*.DS_Store
let NERDTreeRespectWildIgnore=1

" UltiSnips: вставляет текстовый шаблон. Использование: слово + <tab>
Plug 'SirVer/ultisnips'
Plug 'honza/vim-snippets'
Plug 'mlaursen/vim-react-snippets'
let g:UltiSnipsExpandTrigger='<tab>'
let g:UltiSnipsJumpForwardTrigger='<tab>'
let g:UltiSnipsJumpBackwardTrigger='<s-tab>'

" Polyglot: поддержка синтаксиса и отступов для разных языков
Plug 'sheerun/vim-polyglot'
"let g:blade_custom_directives = ['datetime', 'javascript']

" Codi: выполнение кода в vim
"Plug 'metakirby5/codi.vim'

" Javascript: синтаксис для javascript (в том числе в html-файлах)
"Plug 'pangloss/vim-javascript'

" Typescript: подсветка и отступы
"Plug 'leafgarland/typescript-vim'

" Jade: подсветка синтаксиса для jade
"Plug 'digitaltoad/vim-jade'

" Blade highlighting
"Plug 'jwalton512/vim-blade'

" Markdown: подсветка синтаксиса
"Plug 'plasticboy/vim-markdown'
"let g:vim_markdown_folding_disabled = 1

" Table: создание таблиц
"Plug 'dhruvasagar/vim-table-mode'
"let g:table_mode_align_char = ':'
"let g:table_mode_corner_corner = '|'
"let g:table_mode_header_fillchar = "-"
" , + jt: Table enable
"nmap <Leader>jt :TableModeToggle<CR>

" Jshint: проверка js
"Plug 'Shutnik/jshint2.vim'
" , + h: JSHint
"map <silent> <Leader>h :JSHint<CR>

" JSX: подсветка синтаксиса и отступы для JSX
Plug 'maxmellon/vim-jsx-pretty'

" Bbye: удаление ненужных буферов
Plug 'moll/vim-bbye'

" Deoplete: автозавершение
if has('nvim')
  Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
else
  Plug 'Shougo/deoplete.nvim'
  Plug 'roxma/nvim-yarp'
  Plug 'roxma/vim-hug-neovim-rpc'
endif
let g:deoplete#enable_at_startup = 1

"PaperColor: цветовая схема
Plug 'NLKNguyen/papercolor-theme'

" Buffergator: управление буферами
Plug 'jeetsukumaran/vim-buffergator'
let g:buffergator_viewport_split_policy = 'B'
let g:buffergator_suppress_keymaps = 1

" Arsync: asynchronous synchronisation of remote files
Plug 'kenn7/vim-arsync'


" Git support
Plug 'tpope/vim-fugitive'

" Prettier: форматирование для js, ts, less, scss, css, json, graphql and markdown files
Plug 'prettier/vim-prettier', { 'do': 'npm install' }
let g:prettier#autoformat = 0
let g:prettier#exec_cmd_async = 1
let g:prettier#autoformat_require_pragma = 0
let g:prettier#config#semi = 'true'
let g:prettier#config#single_quote = 'true'
let g:prettier#config#bracket_spacing = 'true'
let g:prettier#config#jsx_bracket_same_line = 'true'
let g:prettier#config#trailing_comma = 'none'
let g:prettier#config#print_width = 200
packloadall

call plug#end()

filetype plugin indent on


" ----------------------------------------
" Общие настройки VIM
" ----------------------------------------

" Настройки в режиме чтения
if &readonly
  set laststatus=1
  set ruler
  set cmdheight=1
  set nonumber
  set colorcolumn=0
endif

" Вкладки с файлами и статусная строка
" 0: Никогда не показывать
" 1: Показывать если больше чем 1
" 2: Всегда показывать
set showtabline=1
set laststatus=2

" Команданая строка
" Размер высоты
set cmdheight=1

" Номерация строк
set number
set relativenumber

" Количество символов в номерации строк
set numberwidth=4

" Отображение имени буфера в заголовке терминала
set title

" Запрет переноса строк
set nowrap

" Отступы сверху и снизу при скролле
set scrolloff=10

" Вертикальное окно справа
set splitright


" ----------------------------------------
" Hardcore mode
" ----------------------------------------

" Отключение стрелочек
noremap <Up> <nop>
noremap <Down> <nop>
noremap <Left> <nop>
noremap <Right> <nop>
inoremap <BS> <nop>


" ----------------------------------------
" Дата и время
" ----------------------------------------

set statusline=%<%f%h%m%r\ \[%{&fenc}]\ %=%c\|%l\/%L\ %P\ \[%{strftime('%a\ %d.%m.%Y\ %H:%M\')}\]


" ----------------------------------------
" Цвет
" ----------------------------------------

" Синтаксис
syntax enable

" Фон
set background=light

" Поддержка цвета
set t_Co=256

" Цветовая схема
"colorscheme desert
"colorscheme morning
colorscheme PaperColor


" Цвет невидимых символов
highlight SpecialKey ctermbg=none ctermfg=160

" Цвет колонки-ограничителя
"highlight ColorColumn ctermbg=none ctermfg=11

" Цветная колонка-ограничитель
"set colorcolumn=76
"execute "set colorcolumn=" . join(range(76,335), ',')

" Стили текста за пределами допустимой области
highlight OverLength ctermfg=160

" Допустимая рабочая область
match OverLength /\%480v.\+/


" ----------------------------------------
" Форматирование текста
" ----------------------------------------

" Установить keymap (переключается CTRL + ^)
set keymap=russian-jcukenwin

" По умолчанию - латинская раскладка
set iminsert=0

" По умолчанию - латинская раскладка при поиске
set imsearch=0

" Невидимый курсор мыши при наборе текста
set mousehide

" Кодировка
set termencoding=utf-8
set fileencodings=utf8,cp1251
set encoding=utf-8

" Отключение .swp и резервных файлов
set nobackup
set noswapfile

" Опции при удалении в режиме ввода
set backspace=indent,eol,start

" Умные отступы
"set cin
"set autoindent
set smartindent

" Пробельные символы на кнопке <tab>
set expandtab

" Количество символов за одно нажание на TAB
set tabstop=2

" Количиство символов при автоматическом табе
set shiftwidth=2

" Настройка сессий
set sessionoptions=buffers,folds,sesdir,tabpages,globals,options,resize,winpos


" ----------------------------------------
" Поиск
" ----------------------------------------

" Подсветка искомых значений
set hlsearch

" Выделение слова с знаком '-'
set iskeyword+=-

" Быстрый переход к искомому значению
set incsearch

" Регистр при поиске
" infercase: учитывать
" ignorecase: игнорировать
set ignorecase

" Умный поиск
set smartcase


" ----------------------------------------
" Сворачивание блоков кода
" ----------------------------------------

" Включить сворачивание
set foldenable

" Метод определения блоков свертки
" indent: отступами
" syntax: синтаксический
" manual: вручную
set foldmethod=manual

" Полоса отображения свернутых/развернутых блоков
set foldcolumn=0

" Уровень сверачивания блоков по умолчанию
"set foldlevel=0

" Автоматическое открытие сверток при заходе на них
"set foldopen=all

" Автоматическое закрытие сверток при уходе с них
"set foldclose=all


" ----------------------------------------
" Автозавершение & Синтаксис
" ----------------------------------------

" Автозавершение двойных знаков
imap [ []<left>
imap ( ()<left>
"imap < <><left>
imap { {}<left>
"
" Сигнал ошибке при отсутствии открывающей скобки
set showmatch

" Отключение добавления первого значения при вызове <c-x><c-o>
set completeopt=longest,menuone

" Автозавершение синтаксиса
autocmd FileType css setlocal omnifunc=csscomplete#CompleteCSS
autocmd FileType html,markdown setlocal omnifunc=htmlcomplete#CompleteTags
autocmd FileType javascript setlocal omnifunc=javascriptcomplete#CompleteJS
autocmd FileType xml setlocal omnifunc=xmlcomplete#CompleteTags
autocmd BufNewFile,BufRead *.blade.php set filetype=html

" Автообновление данных конфиг файла VIM при сохранении
autocmd! bufwritepost $MYVIMRC source $MYVIMRC


" ----------------------------------------
" Невидимые символы (пробелы, табуляция)
" ----------------------------------------

" Включение отображения невидимых символов
set list

" Вид табуляции и пробела
"set lcs=tab:│\ ,trail:·,extends:>,precedes:<,nbsp:&
"set lcs=tab:└─,trail:·,extends:>,precedes:<,nbsp:&
"set lcs=tab:│┈,trail:·,extends:>,precedes:<,nbsp:&
"set lcs=tab:▸\ ,trail:·,extends:>,precedes:<,nbsp:&
"set lcs=tab:▸·,trail:·,extends:>,precedes:<,nbsp:&
"set lcs=tab:\ \ ,trail:·,extends:>,precedes:<,nbsp:&
set lcs=tab:·\ ,trail:·,extends:>,precedes:<,nbsp:&


" ----------------------------------------
" Hotkeys
" ----------------------------------------

let mapleader = ','

" , + jv: VIM edit
nmap <leader>jv :vsplit $MYVIMRC<CR>

" , + jb: Форматирование кода
nmap <leader>jb :Prettier<CR>

" , + b: Buffergator
nmap <Leader>b  :BuffergatorToggle<CR>

" , + s: Save remote
nmap <silent> <Leader>s  :ARsyncUp<CR>

" , + f: Файловая система
nmap <silent> <Leader>f :NERDTreeToggle<CR>

" , + p: Открывает предыдущий буфер
nmap <silent> <Leader>p :bp<CR>

" , + n: Открывает следующий буфер
nmap <silent> <Leader>n :bn<CR>

" , + d: Bbye - закрывает файл
nmap <silent> <Leader>d :Bdelete<CR>

" , + g: Поиск слова под курсором в текущей директории
nmap <Leader>g :set operatorfunc=<SID>GrepOperator<CR>g@
vmap <Leader>g :<c-u>call <SID>GrepOperator(visualmode())<CR>

function! s:GrepOperator(type)
  let saved_unnamed_register = @@

  if a:type ==# 'v'
    normal! `<v`>y
  elseif a:type ==# 'char'
    normal! `[v`]y
  else
    return
  endif

  " поиск везде, кроме:
  " - папок node_modules, vendor, .git
  " - папок начинающихся на '_'
  " - файлов начинающихся с '_'
  execute 'grep! -aR ' . shellescape(@@) .
        \ ' . --exclude-dir={node_modules,vendor,.git,_*}
        \ --exclude={package-lock.json,_*,*.pyc}'
  copen

  let @@ = saved_unnamed_register
endfunction

" , + z: Сворачивание функциональных блоков в файле
nmap <Leader>z :call FoldingBlocks()<CR>

function! FoldingBlocks()
  if exists('b:space') == 0
    let b:space = 0
  endif

  execute 'normal zE'

  let i = 0
  let lenline = line('$')
  let currentline = line('.')

  call inputsave()
  let space = input('how many space (current value: ' . b:space . ')? ')
  call inputrestore()

  if strlen(space) != 0
    let b:space = +space
  endif

  while i <= lenline
    let str = getline(i)
    if match(str, '\S') == b:space
      if match(str, '[{[]') != -1
        execute i + 'G'
        execute 'normal $zf%'
      endif
    endif
    let i += 1
  endwhile

  execute currentline + 'G'
  echo ''

endfunction

" , + l: Подсветка координат курсора
map <silent> <Leader>l :call ToggleCursorLight()<CR>

set cursorline
set cursorcolumn
let g:cursorLight=1

function! ToggleCursorLight()
  if(g:cursorLight)
    set nocursorline
    set nocursorcolumn
    let g:cursorLight=0
  else
    set cursorline
    set cursorcolumn
    let g:cursorLight=1
  endif
endfunction

" , + c: Копирование в системный буфер
vmap <silent> <Leader>c "+y<CR>

" , + v: Вставка из системного буфера
nmap <silent> <Leader>v "+p<CR>

" , + w: Git blame (who)
map <silent> <Leader>w :Git blame<CR>
