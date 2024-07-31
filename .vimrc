" ----------------------------------------
" Плагины VIM:
" ----------------------------------------

set nocompatible
filetype off

call plug#begin('~/.vim/plugged')

" Nerdtree: навигация по файлам
Plug 'preservim/nerdtree'
set wildignore+=*.pyc,*.o,*.obj,*.svn,*.swp,*.class,*.hg,*.DS_Store,*.zip,*.tmp
let NERDTreeRespectWildIgnore=1
Plug 'Xuyuanp/nerdtree-git-plugin'

" UltiSnips: сниппеты
Plug 'SirVer/ultisnips'
Plug 'honza/vim-snippets'
let g:UltiSnipsExpandTrigger="<C-m>"
let g:UltiSnipsJumpForwardTrigger="<C-n>"
let g:UltiSnipsJumpBackwardTrigger="<C-p>"
let g:UltiSnipsEditSplit="vertical"

" Polyglot: поддержка синтаксиса и отступов для разных языков
Plug 'sheerun/vim-polyglot'

" Bbye: удаление ненужных буферов
Plug 'moll/vim-bbye'

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

" Easycomplete: автозавершение, lsp, навигация по проекту
Plug 'ycm-core/YouCompleteMe'
let g:ycm_key_list_select_completion = ['<C-n>']
let g:ycm_key_list_previous_completion = ['<C-p>']

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

" Скрыть вывод информации в нумерации
set signcolumn=no

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

" Цветовая схема
colorscheme PaperColor

" Цвет невидимых символов
highlight SpecialKey ctermbg=none ctermfg=124

" Стили текста за пределами допустимой области
highlight OverLength ctermfg=160

" Допустимая рабочая область
match OverLength /\%480v.\+/


" ----------------------------------------
" Форматирование текста
" ----------------------------------------

" Установить keymap
set keymap=russian-jcukenmac

" Переключение языка в режиме ввода
imap <C-l> <C-^>

" Сброс языка при выходе из Insert mode
imap <silent> <ESC> <ESC>:set iminsert=0<CR>

" Переключение языка в режиме поиска
cmap <C-l> <C-^>

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


" ----------------------------------------
" Автозавершение & Синтаксис
" ----------------------------------------

" Автозавершение двойных знаков
imap [ []<left>
imap ( ()<left>
imap { {}<left>

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
set lcs=tab:·\ ,trail:·,extends:>,precedes:<,nbsp:&


" ----------------------------------------
" Hotkeys
" ----------------------------------------

let mapleader = ','

" , + jv: VIM edit
nmap <leader>jv :vsplit $MYVIMRC<CR>

" , + b: Buffergator
nmap <silent> <leader>b :BuffergatorToggle<CR>

" , + s: Save remote
nmap <silent> <leader>s :ARsyncUp<CR>

" , + f: Файловая система
nmap <silent> <leader>f :NERDTreeToggle<CR>

" , + p: Открывает предыдущий буфер
nmap <silent> <leader>p :bp<CR>

" , + n: Открывает следующий буфер
nmap <silent> <leader>n :bn<CR>

" , + d: Bbye - закрывает файл
nmap <silent> <leader>d :Bdelete<CR>

" , + g: Поиск слова под курсором в текущей директории
nmap <leader>g :set operatorfunc=<SID>GrepOperator<CR>g@
vmap <leader>g :<c-u>call <SID>GrepOperator(visualmode())<CR>

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
        \ ' . --exclude-dir={node_modules,vendor,.git,_\*}
        \ --exclude={package-lock.json,_\*,\*.pyc}'
  copen

  let @@ = saved_unnamed_register
endfunction

" , + z: Сворачивание функциональных блоков в файле
nmap <leader>z :call FoldingBlocks()<CR>

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
map <silent> <leader>l :call ToggleCursorLight()<CR>

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
vmap <silent> <leader>c "+y<CR>

" , + v: Вставка из системного буфера
nmap <silent> <leader>v "+p<CR>

" , + w: Git blame (who)
map <silent> <leader>w :Git blame<CR>
