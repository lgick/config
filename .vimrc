" Плагины VIM:

" pathogen    :   менеджер плагинов для VIM                                  :   https://github.com/tpope/vim-pathogen
" nerdtree    :   навигация по файлам                                        :   https://github.com/scrooloose/nerdtree
" snipMate    :   вставляет текстовый шаблон. Использование: слово + <tab>   :   https://github.com/msanders/snipmate.vim
" template    :   шаблоны при создании новых файлов                          :   https://github.com/thinca/vim-template
" javascript  :   синтаксис для javascript (в том числе в html-файлах)       :   https://github.com/pangloss/vim-javascript
" jade        :   подсветка синтаксиса для jade                              :   https://github.com/digitaltoad/vim-jade
" html5       :   подсветка синтаксиса html5, автозавершение                 :   https://github.com/othree/html5.vim
" jsBeautify  :   быстрое форматирование js, html, css                       :   https://github.com/maksimr/vim-jsbeautify
" solarized   :   цветовая схема                                             :   https://github.com/altercation/solarized
" jshint      :   проверка js                                                :   https://github.com/Shutnik/jshint2.vim


" ----------------------------------------
" Общие настройки VIM
" ----------------------------------------

" Загрузка плагинов из папки bundle
filetype off
execute pathogen#infect()
filetype plugin indent on

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

" Solarized настройки
"let g:solarized_termcolors=256
let g:solarized_termtrans=0
let g:solarized_degrade=0
let g:solarized_bold=1
let g:solarized_underline=1
let g:solarized_italic=1
let g:solarized_contrast='normal'
let g:solarized_visibility='low'

" Цветовая схема
colorscheme solarized

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

" Невидимый курсор мыши при наборе текста
set mousehide

" Кодировка
set termencoding=utf-8
set fileencodings=utf8,cp1251
set encoding=utf-8

" Отключение .swp и резервных файлов
set nobackup
set noswapfile

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


" ----------------------------------------
" Поиск
" ----------------------------------------

" Подсветка искомых значений
set hlsearch

" Быстрый переход к искомому значению
set incsearch

" Регистр при поиске
" ignorecase: игнорировать
" smartcase: учитывать
set ignorecase


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

" Автозавершение синтаксиса
autocmd FileType python set omnifunc=pythoncomplete#Complete
autocmd FileType tt2html set omnifunc=htmlcomplete#CompleteTags
autocmd FileType javascript set omnifunc=javascriptcomplete#CompleteJS
autocmd FileType html set omnifunc=htmlcomplete#CompleteTags
autocmd FileType css set omnifunc=csscomplete#CompleteCSS
autocmd FileType xml set omnifunc=xmlcomplete#CompleteTags
autocmd FileType php set omnifunc=phpcomplete#CompletePHP
autocmd FileType c set omnifunc=ccomplete#Complete
autocmd FileType cpp set omnifunc=cppcomplete#Complete
autocmd FileType objc set omnifunc=objcomplete#Complete


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
    colorscheme solarized
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

" F9 Формат файла под стандарт (в работе!)
"autocmd FileType javascript noremap <buffer>  <F9> :call JsBeautify()<cr>
" for html
"autocmd FileType html noremap <buffer> <F9> :call HtmlBeautify()<cr>
" for css or scss
"autocmd FileType css noremap <buffer> <F9> :call CSSBeautify()<cr>

" F10 JSHint
map <silent> <F10> :JSHint<CR>

" F11
" F12
" F13
