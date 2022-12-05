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
set updatetime=300

set backspace=indent,eol,start
set foldmethod=manual
set encoding=utf-8 nobomb

filetype on
syntax on

" GUI
"{{{
colo desert
if !empty(glob("~/.vim/colors/onedark.vim"))
    colo onedark
endif

" 行号，标尺
set nu rnu cul
set scrolloff=5
hi clear LineNr
hi ColorColumn guibg=grey

set noshowcmd
set langmenu=zh_CN
"}}}

" Coc Config
let enableCoc = 1

if enableCoc 
"{{{
let g:coc_global_extensions = [
	\ 'coc-sh',
	\ 'coc-vimlsp',
    \ 'coc-explorer',
    \ 'coc-gitignore',
    \ 'coc-highlight',
    \ 'coc-json',
    \ 'coc-tabnine',
    \ 'coc-yaml',
    \ 'coc-diagnostic',
    \ ]
	" \ 'coc-markdownlint',
    " \ 'coc-snippets',
    " \ 'coc-docker',
	" \ 'coc-java',
	" \ 'coc-jest',
	" \ 'coc-lists',
	" \ 'coc-omnisharp',
	" \ 'coc-prettier',
	" \ 'coc-prisma',
	" \ 'coc-pyright',
	" \ 'coc-sourcekit',
	" \ 'coc-stylelint',
	" \ 'coc-syntax',
	" \ 'coc-tasks',
	" \ 'coc-translator',
	" \ 'coc-tsserver',
	" \ 'coc-vetur',
	" \ 'coc-yank',

inoremap <silent><expr> <TAB>
      \ coc#pum#visible() ? coc#pum#next(1) :
      \ CheckBackspace() ? "\<Tab>" :
      \ coc#refresh()
inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"
inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
                              \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

" GoTo code navigation.
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
" Symbol renaming.
nmap <leader>re <Plug>(coc-rename)
" Coc Command
nnoremap <leader>cm :CocCommand 

" Show documentation in preview window.
nnoremap <silent> <C-q> :call ShowDocumentation()<CR>

" Highlight the symbol and its references when holding the cursor.
autocmd CursorHold * silent call CocActionAsync('highlight')

" Explorer
let g:coc_explorer_global_presets = {
\   '.vim': {
\     'root-uri': '~/.vim',
\   },
\   'cocConfig': {
\      'root-uri': '~/.config/coc',
\   },
\   'tab': {
\     'position': 'tab',
\     'quit-on-open': v:true,
\   },
\   'tab:$': {
\     'position': 'tab:$',
\     'quit-on-open': v:true,
\   },
\   'floating': {
\     'position': 'floating',
\     'open-action-strategy': 'sourceWindow',
\   },
\   'floatingTop': {
\     'position': 'floating',
\     'floating-position': 'center-top',
\     'open-action-strategy': 'sourceWindow',
\   },
\   'floatingLeftside': {
\     'position': 'floating',
\     'floating-position': 'left-center',
\     'floating-width': 50,
\     'open-action-strategy': 'sourceWindow',
\   },
\   'floatingRightside': {
\     'position': 'floating',
\     'floating-position': 'right-center',
\     'floating-width': 50,
\     'open-action-strategy': 'sourceWindow',
\   },
\   'simplify': {
\     'file-child-template': '[selection | clip | 1] [indent][icon | 1] [filename omitCenter 1]'
\   },
\   'buffer': {
\     'sources': [{'name': 'buffer', 'expand': v:true}]
\   },
\ }

endif "---endif---

function! CheckBackspace() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction
function! ShowDocumentation()
  if CocAction('hasProvider', 'hover')
    call CocActionAsync('doHover')
  else
    call feedkeys('K', 'in')
  endif
endfunction
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

nnoremap ZQ :xa!<CR>
nnoremap ZQ :qa!<CR>
" vim default
nnoremap ZZ :x<CR>
"}}}

" Move and Delete Lines
"{{{
noremap H ^
noremap L $
noremap J 15jzz
noremap K 15kzz
nnoremap <C-j> gj
nnoremap <C-k> gk

nnoremap <A-Up> :.-1m.<CR>k
nnoremap <A-Down> :m.+1<CR>
nnoremap dD "_dd
"}}}

" Copy and Paste
"{{{
vnoremap <C-c> "*y

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

" Toggle search hightlight
noremap <leader>sl :set hls!<Bar>set hls?<CR>
" Toggle copy/paste mode
noremap <leader>cv :set rnu! nonu! paste!<CR>

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
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'mhinz/vim-startify'
Plug 'mbbill/undotree'
Plug 'scrooloose/nerdcommenter'

Plug 'dbeniamine/cheat.sh-vim'
Plug 'junegunn/vim-easy-align'
Plug 'jiangmiao/auto-pairs'
Plug 'tpope/vim-surround'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
" Plug 'guns/xterm-color-table.vim'
call plug#end()

"""""""""""""""""""""""""""""""""""""""""
"           Plugin Mapping              " 
"""""""""""""""""""""""""""""""""""""""""
"{{{
" File and Undo Tree
" {{{
" noremap <leader>tt :NERDTreeToggle<CR>
noremap <leader>tt :CocCommand explorer<CR>
noremap <leader>tu :UndotreeToggle<CR>
" set g:undotree_ShortIndicators=1
" set g:undotree_SetFocusWhenToggle=1

" you should install nerdfonts by yourself. default: 0
" let g:NERDTreeGitStatusUseNerdFonts = 1 
" let g:NERDTreeMapChangeRoot = 'l'
" let g:NERDTreeMapJumpParent = 'h'
" let g:NERDTreeMapUpdirKeepOpen = 'H'
" let g:NERDTreeMapJumpNextSibling = 'J'
" let g:NERDTreeMapJumpPrevSibling = 'K'
" let g:NERDTreeMapJumpLastChild = '<C-J>'
" let g:NERDTreeMapJumpFirstChild = '<C-K>'
"
" let g:NERDTreeMapActivateNode = 'o'
"
" let g:NERDTreeMapCloseDir = 'u'
" let g:NERDTreeMapJumpRoot = 'U'
" let g:NERDTreeMapUpdir = 'gu'
" }}}

" Startify Setting
" {{{
nnoremap <leader>st :Startify<CR>

let g:startify_lists = [
     \ { 'type': 'sessions'           , 'header': ['   Sessions'  ] } ,
     \ { 'type': 'bookmarks'          , 'header': ['   Bookmarks' ] } ,
     \ { 'type': 'files'              , 'header': ['   File'      ] } ,
     \ ]

let g:startify_bookmarks = [ 
    \ {'rc': '~/.vimrc'},
    \ {'cf': '~/.vim/coc-settings.json'},
    \ ]

let g:startify_session_persistence = 1
let g:startify_session_autoload = 1

" Run Startify for each tab
" autocmd BufWinEnter *
"     \ if !exists('t:startify_new_tab')
"     \     && empty(expand('%'))
"     \     && empty(&l:buftype)
"     \     && &l:modifiable |
"     \   let t:startify_new_tab = 1 |
"     \   Startify |
"     \ endif
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
nnoremap cm <plug>NERDCommenterToggle<CR>
vnoremap <leader>cm <plug>NERDCommenterToggle
"}}}

" }}}
