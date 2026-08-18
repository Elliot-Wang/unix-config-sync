"""""""""""""""""""""""""""""LeaderF settings"""""""""""""""""""""
" Do not use cache file
let g:Lf_UseCache = 0
" Refresh each time we call leaderf
let g:Lf_UseMemoryCache = 0

" Ignore certain files and directories when searching files
let g:Lf_WildIgnore = {
  \ 'dir': ['.git', '__pycache__', '.DS_Store', '*_cache'],
  \ 'file': ['*.exe', '*.dll', '*.so', '*.o', '*.pyc', '*.jpg', '*.png',
  \ '*.gif', '*.svg', '*.ico', '*.db', '*.tgz', '*.tar.gz', '*.gz',
  \ '*.zip', '*.bin', '*.pptx', '*.xlsx', '*.docx', '*.pdf', '*.tmp',
  \ '*.wmv', '*.mkv', '*.mp4', '*.rmvb', '*.ttf', '*.ttc', '*.otf',
  \ '*.mp3', '*.aac']
  \}

" Do not show fancy icons for Linux server.
if g:is_linux
  let g:Lf_ShowDevIcons = 0
endif

" Only fuzzy-search files names
let g:Lf_DefaultMode = 'FullPath'

" Do not use version control tool to list files under a directory since
" submodules are not searched by default.
let g:Lf_UseVersionControlTool = 0

" Use rg as the default search tool
let g:Lf_DefaultExternalTool = "rg"

" show dot files
let g:Lf_ShowHidden = 1

" Disable default mapping
let g:Lf_ShortcutF = ''
let g:Lf_ShortcutB = ''

" set up working directory for git repository
let g:Lf_WorkingDirectoryMode = 'a'

" Search files in popup window
" nnoremap <silent> gf :<C-U>Leaderf file --popup<CR>

" Grep project files in popup window
" nnoremap <silent> <Leader>se :<C-U>Leaderf rg --no-messages --popup  --nameOnly<CR>

" Search line in current buffer
" nnoremap <silent> <C-f> :<C-U>Leaderf line --popup<CR>

" Search tags in current buffer
nnoremap <silent> gm :<C-U>Leaderf bufTag --popup<CR>

" Switch buffers
" nnoremap <silent> ge :<C-U>Leaderf buffer --popup<CR>

" Search recent files
" nnoremap <silent> go :<C-U>Leaderf mru --popup --absolute-path<CR>

let g:Lf_PopupColorscheme = 'gruvbox_material'

" Change keybinding in LeaderF prompt mode, use ctrl-n and ctrl-p to navigate
" items.
" let g:Lf_CommandMap = {'<C-J>': ['<C-N>'], '<C-K>': ['<C-P>']}

" do not preview results, it will add the file to buffer list
let g:Lf_PreviewResult = {
      \ 'File': 1,
      \ 'Buffer': 1,
      \ 'Mru': 1,
      \ 'Tag': 1,
      \ 'BufTag': 1,
      \ 'Function': 1,
      \ 'Line': 1,
      \ 'Colorscheme': 0,
      \ 'Rg': 1,
      \ 'Gtags': 0
      \}
