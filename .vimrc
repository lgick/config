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
Bundle 'SirVer/ultisnips'
Bundle 'honza/vim-snippets'
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

" Neocomplete: автозавершение
Bundle 'Shougo/neocomplete.vim.git'
let g:acp_enableAtStartup = 0
let g:neocomplete#enable_at_startup = 1
let g:neocomplete#enable_smart_case = 1
let g:neocomplete#sources#syntax#min_keyword_length = 3
let g:neocomplete#lock_buffer_name_pattern = '\*ku\*'

" Colorschemes: цветовые схемы
Bundle 'flazz/vim-colorschemes.git'

" Colorswitcher: переключение цветовых схем
Bundle 'vim-scripts/vim-colorscheme-switcher.git'
Bundle 'xolox/vim-misc.git'
let g:colorscheme_switcher_define_mappings = 0
let g:colorscheme_switcher_keep_background = 1

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
set background=light

" Поддержка цвета
set t_Co=256

" Цветовая схема
try
  colorscheme lucius
catch /^Vim\%((\a\+)\)\=:E185/
  colorscheme desert
endtry

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
match OverLength /\%80v.\+/


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
        \ --exclude="_*"'
  copen

  let @@ = saved_unnamed_register
endfunction

" , + z: Сворачивание функциональных блоков в файле
nmap <Leader>z :call FoldingBlocks()<CR>

function! FoldingBlocks()
  execute 'normal zE'

  let i = 0
  let lenline = line('$')
  let currentline = line('.')

  call inputsave()
  let space = input('how many space (default: 0)? ')
  call inputrestore()

  if !strlen(space)
    let space = 0
  endif

  while i <= lenline
    let str = getline(i)
    if match(str, '\S') == space
      if match(str, '[{[]') > 0
        execute i + 'G'
        execute 'normal $zf%'
      endif
    endif
    let i += 1
  endwhile

  execute currentline + 'G'
  echo ''

endfunction

" , + sn: Меняет на следующую цветовую схему
nmap <silent> <Leader>sn :NextColorScheme<CR>

" , + sp: Меняет на предыдущую цветовую схему
nmap <silent> <Leader>sp :PrevColorScheme<CR>

" , + s: Меняет на рандомную цветовую схему
nmap <silent> <Leader>s :RandomColorScheme<CR>

" , + h: JSHint
map <silent> <Leader>h :JSHint<CR>

" , + l: Подсветка координат курсора
map <silent> <Leader>l :call ToggleCursorLight()<CR>

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

" , + c: Копирование в системный буфер
vmap <silent> <Leader>c "+y<CR>

" , + v: Вставка из системного буфера
nmap <silent> <Leader>v "+p<CR>
