" ----------------------------------------
" Плагины VIM:
" ----------------------------------------

set nocompatible
filetype off

set rtp+=~/.vim/bundle/vundle/
call vundle#rc()

" let Vundle manage Vundle
Bundle 'gmarik/vundle'

" My bundles here:
" Nerdtree: навигация по файлам
Bundle 'scrooloose/nerdtree'

" UltiSnips: вставляет текстовый шаблон. Использование: слово + <tab>
Bundle 'SirVer/ultisnips.git'
let g:UltiSnipsExpandTrigger='<tab>'
let g:UltiSnipsJumpForwardTrigger='<tab>'
let g:UltiSnipsJumpBackwardTrigger='<s-tab>'

" Template: шаблоны при создании новых файлов
Bundle 'thinca/vim-template'

" Javascript: синтаксис для javascript (в том числе в html-файлах)
Bundle 'pangloss/vim-javascript'

" Jade: подсветка синтаксиса для jade
Bundle 'digitaltoad/vim-jade'

" Markdown: подсветка синтаксиса
Bundle 'plasticboy/vim-markdown'
let g:vim_markdown_folding_disabled=1

" Html5: подсветка синтаксиса html5, автозавершение
Bundle 'othree/html5.vim'

" Solarized: цветовая схема
Bundle 'altercation/vim-colors-solarized'
"let g:solarized_termcolors=256
let g:solarized_termtrans=0
let g:solarized_degrade=0
let g:solarized_bold=1
let g:solarized_underline=1
let g:solarized_italic=1
let g:solarized_contrast='normal'
let g:solarized_visibility='low'

" Jshint: проверка js
Bundle 'Shutnik/jshint2.vim'

" Bbye: удаление ненужных буферов
Bundle 'moll/vim-bbye.git'

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

" Количество символов в номерации строк
set numberwidth=4

" Отображение имени буфера в заголовке терминала
set title

" Запрет переноса строк
set nowrap

" Отступы сверху и снизу при скролле
set scrolloff=10


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

if has("win32")
  set statusline=%<%f%h%m%r%=%{strftime(\"%I:%M:%S\\%p,\ %a\ %b\ %d,\ %Y\")}\ %{&ff}\ %l,%c%V\ %P
else
  set statusline=%<%f%h%m%r%=%{strftime(\"%l:%M:%S\\%p,\ %a\ %b\ %d,\ %Y\")}\ %{&ff}\ %l,%c%V\ %P
endif


" ----------------------------------------
" Цвет
" ----------------------------------------

" Синтаксис
syntax enable

" Фон
set background=dark

" Поддержка цвета
set t_Co=256

" Цветовая схема
try
  colorscheme solarized
catch /^Vim\%((\a\+)\)\=:E185/
  colorscheme desert
endtry

" Цвет невидимых символов
highlight SpecialKey ctermbg=none ctermfg=15

" Цвет колонки-ограничителя
highlight ColorColumn ctermbg=none ctermfg=11

" Цветная колонка-ограничитель
"set colorcolumn=76
execute "set colorcolumn=" . join(range(76,335), ',')

" Стили текста за пределами допустимой области
"highlight OverLength ctermfg=234

" Допустимая рабочая область
"match OverLength /\%76v.\+/


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

" Вид курсора при разных режимах
let &t_SI = "\<Esc>]50;CursorShape=1\x7"
let &t_EI = "\<Esc>]50;CursorShape=0\x7"


" ----------------------------------------
" Поиск
" ----------------------------------------

" Подсветка искомых значений
set hlsearch

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
" Плагины & Автозавершение
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

" Ввод выбранного значения при нажатии Enter
inoremap <expr> <CR> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"

" Автозавершение синтаксиса
autocmd FileType css setlocal omnifunc=csscomplete#CompleteCSS
autocmd FileType html,markdown setlocal omnifunc=htmlcomplete#CompleteTags
autocmd FileType javascript setlocal omnifunc=javascriptcomplete#CompleteJS
autocmd FileType python setlocal omnifunc=pythoncomplete#Complete
autocmd FileType xml setlocal omnifunc=xmlcomplete#CompleteTags


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

" F2 Файловая система
map <silent> <F2> :NERDTreeToggle<CR>

" F3 Сворачивание блоков кода
inoremap <F3> <C-O>za
nnoremap <F3> za
onoremap <F3> <C-C>za
vnoremap <F3> zf

" F4 Переключения режима вставки
set pastetoggle=<F4>

" F5 Открывает предыдущий буфер
map <silent> <F5> :bprevious<CR>

" F6 Открывает следующий буфер
map <silent> <F6> :bnext<CR>

" F7 Подсветка координат курсора
set nocursorline
set nocursorcolumn
let g:cursorLight=0

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

map <silent> <F7> :call ToggleCursorLight()<CR>

" F8 Меняет цветовую схему
let g:userScheme=0

function! ToggleScheme()
  if(g:userScheme)
    try
      colorscheme solarized
    catch /^Vim\%((\a\+)\)\=:E185/
      colorscheme desert
    endtry
    highlight SpecialKey ctermbg=none ctermfg=15
    highlight ColorColumn ctermbg=none ctermfg=11
    let g:userScheme=0
  else
    colorscheme desert
    highlight SpecialKey ctermbg=none ctermfg=15
    highlight ColorColumn ctermbg=none ctermfg=11
    let g:userScheme=1
  endif
endfunction

map <silent> <F8> :call ToggleScheme()<CR>

" F9 JSHint
map <silent> <F9> :JSHint<CR>

" F10 Bbye
map <silent> <F10> :Bdelete<CR>

" F11
" F12
" F13
