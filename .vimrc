"""""""""""""""""""""""""""""""""""""""""
"              General                  " 
"""""""""""""""""""""""""""""""""""""""""
"{{{
set nocompatible
set nobackup
set noswapfile

set history=1024
set wildmenu
set autochdir
set whichwrap=b,s,<,>,[,]
" 搜索默认配置
set hls is ic scs 

set backspace=indent,eol,start
set foldmethod=marker
set encoding=utf-8 nobomb

filetype on
syntax on
"}}}

" GUI
"{{{
colo desert

" 行号，标尺
set nu rnu cul
set scrolloff=5
hi clear LineNr
hi ColorColumn guibg=grey

set noshowcmd
set langmenu=zh_CN

" 不同模式下的光标样式
" unix 环境下不需要
" let &t_SI = "\<Esc>]50;CursorShape=1\x7"
" let &t_SR = "\<Esc>]50;CursorShape=2\x7"
" let &t_EI = "\<Esc>]50;CursorShape=0\x7"
"}}}


" Format Indent
"{{{
" 自动添加缩进量, 智能添加缩进量
set ai si
" 缩进四，tab转空格
set ts=4 sts=4 sw=4 et
vnoremap < <gv
vnoremap > >gv

autocmd FileType yaml setlocal ts=2 sts=2 sw=2 et
"}}}
 

"""""""""""""""""""""""""""""""""""""""""
"             Mappings                  " 
"""""""""""""""""""""""""""""""""""""""""
"{{{
let mapleader=" "

noremap <Leader>rc :source ~/.vimrc<CR>

" Save and exit
"{{{
noremap S :w<CR>
noremap Q :bd<CR>
noremap <C-q> :qa!<CR>
"}}}

" Move
"{{{
noremap H ^
noremap L $
noremap J 15<C-e>
noremap K 15<C-y>
nnoremap j gj
nnoremap k gk
"}}}

" Copy and Paste
"{{{
nnoremap Y y$
nnoremap p gp

nnoremap P "*gp
vnoremap Y "*y
inoremap <C-v> <C-r>*
" To insert unicode characters
inoremap <C-b> <C-v>
"}}}

" Move and Delete Lines
" {{{
nnoremap <A-Up> :.-1m.<CR>k
nnoremap <A-Down> :m.+1<CR>
nnoremap dD "_dd
"}}}

" Split Windows
"{{{
nnoremap s <nop>
nnoremap sk :set splitbelow<CR>:split<CR>		" 下分屏
nnoremap sj :set nosplitbelow<CR>:split<CR>		" 上分屏
nnoremap sl :set nosplitright<CR>:vsplit<CR>	" 右分屏 
nnoremap sh :set splitright<CR>:vsplit<CR>		" 左分屏	
nnoremap sH <C-w>t<C-w>H 	                    " 竖向分屏换左右分屏
nnoremap sJ <C-w>t<C-w>J 	                    " 竖向分屏换左右分屏
nnoremap sK <C-w>t<C-w>K		                " 左右分屏换竖向分屏
nnoremap sL <C-w>t<C-w>L		                " 左右分屏换竖向分屏
nnoremap sc <C-w>c                              " 关闭当前分屏
"}}}

" Move to Windows
"{{{
nnoremap <LEADER>k <C-w>k	" 光标到上屏
nnoremap <LEADER>j <C-w>j	" 光标到下屏
nnoremap <LEADER>h <C-w>h	" 光标到左屏
nnoremap <LEADER>l <C-w>l	" 光标到右屏
"}}}

" Resize Windows
"{{{
nnoremap <leader><up> :res +5<CR>				" 分屏线上移
nnoremap <leader><down> :res -5<CR>				" 分屏线下移
nnoremap <leader><left> :vertical resize+5<CR>	" 分屏线左移
nnoremap <leader><right> :vertical resize-5<CR>	" 分屏线右移
"}}}

" Tabs of Windows
"{{{
nnoremap tn :tabe<CR>          	" 打开新选项卡
nnoremap tc :tabclose<CR>       " 关闭选项卡
nnoremap tH :-tabnext<CR>	    " 到左边的选项卡
nnoremap tL :+tabnext<CR>	    " 到右边的选项卡
"}}}

" Find and Replace
noremap \s :%s///g<left><left><left>
vnoremap s y:s/<C-R>"//g<left><left>
vnoremap S y:%s/<C-R>"//g<left><left>

" Cancel highlight
noremap <leader>nl :set nohls<CR>
" Enable hightlight
noremap <leader>hl :set hls<CR>
" Set no number, ready for copy
noremap <leader>no :set nornu nonu<CR>
" Set number
noremap <leader>nu :set rnu nu<CR>

" Buffers
"{{{
noremap th :bp!<CR>
noremap tl :bn!<CR>
noremap td :bd<CR>
"}}}
"
" Execute and Run
"{{{
" Open Terminal
noremap <LEADER>/ :set splitbelow<CR>:split<CR>:res +10<CR>:term<CR>

" Compile function
noremap <F5> :call CompileRunGcc()<CR>
func! CompileRunGcc()
    if &filetype == 'c'
        exec "!g++ % -o %<"
        exec "!time ./%<"
    elseif &filetype == 'cpp'
        exec "!g++ -std=c++11 % -Wall -o %<"
        term ./%<
        :winc J
        :res -10
    elseif &filetype == 'java'
        exec "!javac %"
        exec "!time java %<"
    elseif &filetype == 'python'
        term python3 %
        :winc J
        :res -10
    elseif &filetype == 'html'
        silent! exec "!".g:mkdp_browser." % &"
    elseif &filetype == 'markdown'
        exec "MarkdownPreview"
    elseif &filetype == 'javascript'
        term export DEBUG="INFO,ERROR,WARNING"; node --trace-warnings .
        :winc J
        :res -10
    elseif &filetype == 'go'
        term go run .
        :winc J
        :res -10
    elseif &filetype == 'vim'
        :source %
    endif
endfunc
"}}}

"}}}

"""""""""""""""""""""""""""""""""""""""""
"                Plugin                 " 
"""""""""""""""""""""""""""""""""""""""""
call plug#begin()
Plug 'junegunn/vim-easy-align'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'mhinz/vim-startify'
Plug 'preservim/nerdtree'
Plug 'mbbill/undotree'
Plug 'scrooloose/nerdcommenter'
Plug 'ryanoasis/vim-devicons'
Plug 'tpope/vim-surround'
" Plug 'guns/xterm-color-table.vim'
call plug#end()

"""""""""""""""""""""""""""""""""""""""""
"           Plugin Mapping              " 
"""""""""""""""""""""""""""""""""""""""""
"{{{
" File and Undo Tree
" {{{
noremap tt :NERDTreeToggle<CR>
noremap tu :UndotreeToggle<CR>
" set g:undotree_ShortIndicators=1
" set g:undotree_SetFocusWhenToggle=1
" }}}

" Startify Setting
" {{{
nnoremap <leader>st Startify

let g:startify_lists = [
     \ { 'type': 'sessions'           , 'header': ['   Sessions'  ] } ,
     \ { 'type': 'bookmarks'          , 'header': ['   Bookmarks' ] } ,
     \ { 'type': 'files'              , 'header': ['   File'      ] } ,
     \ ]

let g:startify_bookmarks = [ 
    \ {'rc': '~/.vimrc'},
    \ ]

" Run Startify for each tab
autocmd BufWinEnter *
    \ if !exists('t:startify_new_tab')
    \     && empty(expand('%'))
    \     && empty(&l:buftype)
    \     && &l:modifiable |
    \   let t:startify_new_tab = 1 |
    \   Startify |
    \ endif
" }}}

" FZF
"{{{
noremap <leader>bf :Buffers<CR>
noremap <leader>se :Files<CR>
noremap <C-f> :Lines<CR>
"}}}

" Airline Bar
" {{{
let g:airline_extensions = ['branch', 'tabline', 'wordcount']
" atomic  亮色调的
" badwolf 也是亮色调，带一点金色 
" bash16 系列，应该是色调更加丰富
" let g:airline_theme='alduin'

let g:airline_section_z = '%v:%l/%L %p%%%'

let g:airline#extensions#tabline#show_close_button = 0
let g:airline#extensions#tabline#formatter = 'unique_tail'
let g:airline#extensions#tabline#show_tab_count = 0
let g:airline#extensions#tabline#show_tab_type = 0
let g:airline#extensions#tabline#show_tab_nr = 0
let g:airline#extensions#wordcount#enabled = 1
let airline#extensions#tabline#ignore_bufadd_pat =
        \ '\c\vgundo|undotree|vimfiler|tagbar|nerd_tree'
let g:airline#extensions#wordcount#filetypes =
            \ ['asciidoc', 'help', 'mail', 'nroff', 'org', 'plaintex', 'rst', 'tex', 'text']
let g:airline#extensions#wordcount#formatter = 'default'
let g:airline_mode_map = {
  \ '__'     : '-',
  \ 'c'      : 'Cm',
  \ 'i'      : 'Is',
  \ 'ic'     : 'Ic',
  \ 'ix'     : 'Ix',
  \ 'n'      : 'Nm',
  \ 'multi'  : 'Mt',
  \ 'ni'     : 'Ni',
  \ 'no'     : 'No',
  \ 'R'      : 'Rp',
  \ 'Rv'     : 'Rv',
  \ 's'      : 'S',
  \ 'S'      : 'S',
  \ ''     : 'S',
  \ 't'      : 'T',
  \ 'v'      : 'Vs',
  \ 'V'      : 'Vl',
  \ ''     : 'Vb',
  \ }
set laststatus=2
"}}}

" Commmenter
"{{{
" NerdCommenter Setting
" {{{
" Add spaces after comment delimiters by default
let g:NERDSpaceDelims = 1

" Use compact syntax for prettified multi-line comments
let g:NERDCompactSexyComs = 1

" Align line-wise comment delimiters flush left instead of following code indentation
let g:NERDDefaultAlign = 'left'

" Set a language to use its alternate delimiters by default
let g:NERDAltDelims_java = 1

" Add your own custom formats or override the defaults
let g:NERDCustomDelimiters = { 'c': { 'left': '/**','right': '*/' } }

" Allow commenting and inverting empty lines (useful when commenting a region)
let g:NERDCommentEmptyLines = 1

" Enable trimming of trailing whitespace when uncommenting
let g:NERDTrimTrailingWhitespace = 1

" Enable NERDCommenterToggle to check all selected lines is commented or not 
let g:NERDToggleCheckAllLines = 1

" Enable Default Mappings
let g:NERDCreateDefaultMappings = 0
" }}}

" NerdCommenter Mapping
"{{{
map <leader>cm <plug>NERDCommenterToggle
"Toggles the comment state of the selected line(s). If the topmost selected line is commented, all selected lines are uncommented and vice versa.

"map <plug>NERDCommenterNested
"Same as cc but forces nesting.

"map <plug>NERDCommenterMinimal
"Comments the given lines using only one set of multipart delimiters.

"map <plug>NERDCommenterSexy
"Comments out the selected lines with a pretty block formatted layout.

"map <plug>NERDCommenterYank
"Same as cc except that the commented line(s) are yanked first.
"}}}

" }}}
