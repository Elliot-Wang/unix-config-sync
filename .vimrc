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
set nowrap

" 搜索默认配置
set hls is ic scs 
set updatetime=300

set backspace=indent,eol,start
set foldmethod=manual
set encoding=utf-8 nobomb

filetype on
syntax on

" # Native autocompletion
" {{{
" Make Vim completion popup menu work just like in an IDE
" set completeopt=longest,menuone
" inoremap <expr> <Tab> pumvisible() ? "\<C-y>" : "\<C-g>u\<Tab>"
" }}}

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

" 实时搜索结果预览
set incsearch

" 使用 ripgrep 作为 grep 程序（如果已安装）
if executable('rg')
  set grepprg=rg\ --vimgrep\ --no-heading
  set grepformat=%f:%l:%c:%m
endif

" 保存折叠状态
augroup remember_folds
  autocmd!
  autocmd BufWinLeave * if expand('%') != '' | mkview | endif
  autocmd BufWinEnter * if expand('%') != '' | silent! loadview | endif
augroup END

" 离开插入模式时自动保存
autocmd InsertLeave * if &modified && !&readonly | update | endif
" 窗口失去焦点时自动保存
autocmd FocusLost * if &modified && !&readonly | update | endif

" 自动保存会话
augroup auto_session
  autocmd!
  autocmd VimLeave * execute 'mksession! ~/.vim/sessions/last.vim'
augroup END
" 快捷键加载上次会话
nnoremap <Leader>ss :source ~/.vim/sessions/last.vim<CR>
"}}}

" Format Indent
"{{{
" 自动添加缩进量, 智能添加缩进量
set ai si
" 缩进四，tab转空格
set ts=4 sts=4 sw=4 et
vnoremap < <gv
vnoremap > >gv

" 为不同文件类型设置不同的缩进
augroup file_types
  autocmd!
  autocmd FileType javascript,typescript,html,css,yaml setlocal ts=2 sts=2 sw=2
  autocmd FileType python setlocal ts=4 sts=4 sw=4
  autocmd FileType markdown setlocal wrap linebreak
augroup END
" Difference
" {{{
let s:isWin = has('win32') || has('win64')
let s:enableCoc = 1
" }}}

" Coc Config
"{{{
if s:enableCoc 
    let g:coc_global_extensions = [
        \ 'coc-vimlsp',
        \ 'coc-gitignore',
        \ 'coc-highlight',
        \ 'coc-json',
        \ 'coc-yaml',
        \ 'coc-diagnostic',
        \ 'coc-lists',
        \ 'coc-tabnine',
        \ ]
    if !s:isWin
        call add(g:coc_global_extensions, 'coc-sh')
        call add(g:coc_global_extensions, 'coc-explorer')
    endif
    " if has('python3')
    "     call add(g:coc_global_extensions, 'coc-snippets')
    " endif

    " Use tab for trigger completion with characters ahead and navigate
    " NOTE: There's always complete item selected by default, you may want to enable
    " no select by `"suggest.noselect": true` in your configuration file
    " NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
    " other plugin before putting this into your config
    " 和X-mode的原生自动补全无法兼容
    " inoremap <silent><expr> <TAB>
    "       \ coc#pum#visible() ? coc#pum#next(1) :
    "       \ CheckBackspace() ? "\<Tab>" :
    "       \ coc#refresh()
    " inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"

    " Make <CR> to accept selected completion item or notify coc.nvim to format
    " <C-g>u breaks current undo, please make your own choice
    inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
                                  \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

    let g:coc_snippet_next = '<tab>'
    " ----自动补全快捷键 tab, shift-tab, enter---- END

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

    " Highlight the symbol and its references when holding the cursor.
    autocmd CursorHold * silent call CocActionAsync('highlight')


endif "---endif enableCoc---

function! CheckBackspace() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction
"}}}

"}}}
 

"""""""""""""""""""""""""""""""""""""""""
"             Mappings                  " 
"""""""""""""""""""""""""""""""""""""""""
"{{{
let mapleader=" "

if s:isWin
    noremap <Leader>rc :source ~/_vimrc<CR>
else
    noremap <Leader>rc :source ~/.vimrc<CR>
endif

" Save and exit
"{{{
nnoremap S :w<CR>
nnoremap Q :bd<CR>

nnoremap ZS :xa!<CR>
nnoremap ZQ :qa!<CR>
" vim default
nnoremap ZZ :x<CR>
"}}}

" Move
"{{{
noremap H ^
noremap L $
noremap J 15jzz
noremap K 15kzz
nnoremap <C-j> gj
nnoremap <C-k> gk
"}}}

" Copy and Paste
"{{{
" vnoremap Y "*y
" 系统剪贴板集成
set clipboard=unnamed,unnamedplus
" Toggle copy/paste mode
noremap <Leader>cv :set rnu! nonu! paste!<CR>

" nonsense in macos
if s:isWin
    vnoremap <C-c> "*y
    inoremap <C-v> <C-r>*
    " To insert unicode characters
    inoremap <C-b> <C-v>
endif
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
nnoremap sL <C-W>L 	                    " 左右分屏换竖向分屏
nnoremap sK <C-W>K 	                    " 竖向分屏换左右分屏
nnoremap sJ <C-W>J		                " 竖向分屏换左右分屏
nnoremap sH <C-W>H		                " 左右分屏换竖向分屏
nnoremap sc <C-W>c                              " 关闭当前分屏
"}}}

" Move to Windows
"{{{
nnoremap <Leader>k <C-W>k	" 光标到上屏
nnoremap <Leader>j <C-W>j	" 光标到下屏
nnoremap <Leader>h <C-W>h	" 光标到左屏
nnoremap <Leader>l <C-W>l	" 光标到右屏
"}}}

" Resize Windows
"{{{
nnoremap <Leader><UP> :res +5<CR>				" 分屏线上移
nnoremap <Leader><DOWN> :res -5<CR>				" 分屏线下移
nnoremap <Leader><LEFT> :vertical resize+5<CR>	" 分屏线左移
nnoremap <Leader><RIGHT> :vertical resize-5<CR>	" 分屏线右移
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

" Toggle search hightlight
noremap <Leader>sl :set hls!<Bar>set hls?<CR>

" Buffers
"{{{
noremap th :bp!<CR>
noremap tl :bn!<CR>
noremap td :bd<CR>
noremap tD :bd!<CR>
"}}}
"
" Execute and Run
"{{{
" Open Terminal
noremap <Leader>/ :bel term<CR>
" Esc to Normal mode
tnoremap <C-[> <C-\><C-n>

" Compile function
noremap <F5> :call CompileRun()<CR>
func! CompileRun()
    if &filetype == 'c'
        exec "!g++ % -o %<"
        exec "!time ./%<"
    elseif &filetype == 'cpp'
        exec "!g++ -std=c++11 % -Wall -o %<"
        term ./%<
    elseif &filetype == 'java'
        exec "!javac %"
        exec "!time java %<"
    elseif &filetype == 'python'
        term python3 %
    elseif &filetype == 'html'
        silent! exec "!".g:mkdp_browser." % &"
    elseif &filetype == 'markdown'
        exec "MarkdownPreview"
    elseif &filetype == 'javascript'
        term zsh -c "export DEBUG=\"INFO,ERROR,WARNING\" && node --trace-warnings %"
    elseif &filetype == 'go'
        term go run .
    elseif &filetype == 'zsh'
        :source %:p
    elseif &filetype == 'vim'
        :source %:p
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
Plug 'chriszarate/yazi.vim'
Plug 'nathangrigg/vim-beancount'

if has('win32') || has('win64')
    Plug 'preservim/nerdtree' |
      \ Plug 'ryanoasis/vim-devicons' |
      \ Plug 'tiagofumo/vim-nerdtree-syntax-highlight'
      " \ Plug 'Xuyuanp/nerdtree-git-plugin' |
endif

" Plug 'dbeniamine/cheat.sh-vim'
Plug 'junegunn/vim-easy-align'
Plug 'jiangmiao/auto-pairs'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-repeat'
" Plug 'mg979/vim-visual-multi'
Plug 'terryma/vim-multiple-cursors'
Plug 'chiedo/vim-case-convert'

" improve motion
Plug 'vim-scripts/argtextobj.vim'
Plug 'machakann/vim-highlightedyank'
Plug 'michaeljsmith/vim-indent-object'

" Plug 'SirVer/ultisnips'
" Snippets are separated from the engine. Add this if you want them:
Plug 'honza/vim-snippets'

Plug 'neoclide/coc.nvim', {'branch': 'release'}

Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'chengzeyi/fzf-preview.vim'
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'
" Plug 'guns/xterm-color-table.vim'
call plug#end()

"""""""""""""""""""""""""""""""""""""""""
"           Plugin Mapping              " 
"""""""""""""""""""""""""""""""""""""""""
"{{{
" File and Undo Tree
" {{{
if s:isWin
    noremap <Leader>tt :NERDTreeToggle<CR>
    " you should install nerdfonts by yourself. default: 0
    let g:NERDTreeGitStatusUseNerdFonts = 1 
    let g:NERDTreeMapChangeRoot = 'l'
    let g:NERDTreeMapJumpParent = 'h'
    let g:NERDTreeMapUpdirKeepOpen = 'H'
    let g:NERDTreeMapJumpNextSibling = 'J'
    let g:NERDTreeMapJumpPrevSibling = 'K'
    let g:NERDTreeMapJumpLastChild = '<C-J>'
    let g:NERDTreeMapJumpFirstChild = '<C-K>'
    
    let g:NERDTreeMapActivateNode = 'o'
    
    let g:NERDTreeMapCloseDir = 'u'
    let g:NERDTreeMapJumpRoot = 'U'
    let g:NERDTreeMapUpdir = 'gu'

    let g:NERDTreeDirArrowExpandable=">"
    let g:NERDTreeDirArrowCollapsible="v"
else
    noremap <Leader>tt :CocCommand explorer<CR>
endif
noremap <Leader>tu :UndotreeToggle<CR>
" set g:undotree_ShortIndicators=1
" set g:undotree_SetFocusWhenToggle=1

" }}}

"{{{
" GoTo code navigation.
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
" Find symbol of current document.
nnoremap <silent><nowait> gl  :CocList outline<CR>
" Search workspace symbols.
" nnoremap <silent><nowait> gs  :CocList -I symbols<cr>
" Symbol renaming.
nmap <Leader>re <Plug>(coc-rename)
" Coc Command

" " Use <C-l> for trigger snippet expand.
" imap <C-l> <Plug>(coc-snippets-expand)
"
" " Use <C-j> for select text for visual placeholder of snippet.
" vmap <C-j> <Plug>(coc-snippets-select)
"
" " Use <C-j> for jump to next placeholder, it's default of coc.nvim
" let g:coc_snippet_next = '<c-j>'
"
" " Use <C-k> for jump to previous placeholder, it's default of coc.nvim
" let g:coc_snippet_prev = '<c-k>'
"
" " Use <C-j> for both expand and jump (make expand higher priority.)
" imap <C-j> <Plug>(coc-snippets-expand-jump)
"
" " Use <leader>x for convert visual selected code to snippet
" " xmap <leader>x  <Plug>(coc-convert-snippet)

function! ShowDocumentation()
  if CocAction('hasProvider', 'hover')
    call CocActionAsync('doHover')
  " else
    " call feedkeys('K', 'in')
  endif
endfunction

" Show documentation in preview window.
nnoremap <silent> <C-q> :call ShowDocumentation()<CR>

" Mappings for CoCList
" Show all diagnostics.
" nnoremap <silent><nowait> <space>dg  :CocList diagnostics<cr>
" Manage extensions.
nnoremap <silent><nowait> <Leader>ex  :CocList extensions<CR>
" Show commands.
" nnoremap <silent><nowait> <Leader>cm  :CocList commands<cr>
nnoremap <silent><nowait> <Leader>cm  :CocList<CR>

" Do default action for next item.
" nnoremap <silent><nowait> <Leader>j  :<C-u>CocNext<CR>
" Do default action for previous item.
" nnoremap <silent><nowait> <Leader>k  :<C-u>CocPrev<CR>
" Resume latest coc list.
" nnoremap <silent><nowait> <Leader>p  :<C-u>CocListResume<CR>

"}}}


" Startify Setting
" {{{
nnoremap <Leader>st :Startify<CR>

let g:startify_lists = [
     \ { 'type': 'commands',  'header': ['   Commands'   ] } ,
     \ { 'type': 'sessions',  'header': ['   Sessions'  ] } ,
     \ { 'type': 'bookmarks', 'header': ['   Bookmarks' ] } ,
     \ { 'type': 'files',     'header': ['   File'      ] } ,
     \ { 'type': 'dir',       'header': ['   MRU '. getcwd()] },
     \ ]

if s:isWin
    let g:startify_bookmarks = [ 
        \ {'rc': '~/_vimrc'},
        \ {'rg': '~/_gvimrc'},
        \ {'cf': '~/vimfiles/coc-settings.json'},
        \ ]
else
    let g:startify_bookmarks = [ 
        \ {'rc': '~/.vimrc'},
        \ {'ic': '~/.ideavimrc'},
        \ {'cf': '~/.vim/coc-settings.json'},
        \ ]
endif

let g:startify_skiplist = [
       \ '\.vimgolf',
       \ '^/tmp',
       \ '/project/.*/documentation',
       \ escape(fnamemodify($HOME, ':p'), '\') .'mysecret.txt',
       \ ]

let g:startify_commands = [
    \ {'sl': ['Load Latest Session', 'silent! source ~/.vim/sessions/last.vim']},
    \ ]

let g:startify_session_persistence = 1
let g:startify_session_autoload = 1

" FZF
" Most commands support CTRL-T / CTRL-X / CTRL-V key bindings to open 
" in a new tab, a new split, or in a new vertical split
"{{{
nnoremap gt :Buffers<CR>
nnoremap gm :FZFMarks<CR>
nnoremap g' :Jumps<CR>
nnoremap go :History<CR>
nnoremap <C-p> :Commands<CR>
" current buffer
nnoremap <C-f> :FZFBLines<CR>   

" all buffers
" nnoremap <C-S-f> :Lines<CR>
"}}}

" yazi
" {{{
nnoremap <C-o> :YaziWorkingDirectory<CR>
" }}}

" argtextobj
"{{{
let g:argtextobj_pairs="[:],(:),{:}"
"}}}

" fugitive
" {{{
nmap <Leader>bl :Git blame<CR>
nmap <Leader>gl :Git log<CR>
" }}}

" gitgutter
" {{{
nmap ]h <Plug>(GitGutterNextHunk)
nmap [h <Plug>(GitGutterPrevHunk)

" conflict with leader+h (move to left windows)
" nmap <Leader>hp <Plug>(GitGutterPreviewHunk)
" nmap <Leader>hs <Plug>(GitGutterStageHunk)
" nmap <Leader>hu <Plug>(GitGutterUndoHunk)
" }}}

" vim-easy-align
"{{{
" Start interactive EasyAlign in visual mode (e.g. vipga)
xmap ga <Plug>(EasyAlign)
" Start interactive EasyAlign for a motion/text object (e.g. gaip)
nmap ga <Plug>(EasyAlign)
"}}}

" vim-multiple-cursors
"{{{
let g:multi_cursor_use_default_mapping=0

" Default mapping
let g:mucti_cursor_start_word_key      = '<C-n>'
let g:multi_cursor_select_all_word_key = '<C-S-n>'
let g:multi_cursor_start_key           = 'g<C-n>'
let g:multi_cursor_select_all_key      = 'g<C-S-n>'
let g:multi_cursor_next_key            = '<C-n>'
let g:multi_cursor_prev_key            = '<C-p>'
let g:multi_cursor_skip_key            = '<C-x>'
let g:multi_cursor_quit_key            = '<Esc>'
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
" let g:airline_mode_map = {
"   \ '__'     : '-',
"   \ 'c'      : 'Cm',
"   \ 'i'      : 'Is',
"   \ 'ic'     : 'Ic',
"   \ 'ix'     : 'Ix',
"   \ 'n'      : 'Nm',
"   \ 'multi'  : 'Mt',
"   \ 'ni'     : 'Ni',
"   \ 'no'     : 'No',
"   \ 'R'      : 'Rp',
"   \ 'Rv'     : 'Rv',
"   \ 's'      : 'S',
"   \ 'S'      : 'S',
"   \ ''     : 'S',
"   \ 't'      : 'T',
"   \ 'v'      : 'Vs',
"   \ 'V'      : 'Vl',
"   \ ''     : 'Vb',
"   \ }
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
nnoremap <C-_> <plug>NERDCommenterToggle<CR>
vnoremap <C-_> <plug>NERDCommenterToggle
"}}}

"}}}
