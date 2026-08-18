" Set quickfix window height, see also https://github.com/lervag/vimtex/issues/1127
function! AdjustWindowWidth(minWidth, maxWidth)
  execute max([a:minWidth, a:maxWidth]) . ' wincmd |'
endfunction

function! AdjustWindowHeight(minheight, maxheight)
  execute max([a:minheight, min([line('$') + 1, a:maxheight])]) . ' wincmd _'
endfunction

function! AdjustWindows()
  execute AdjustWindowHeight(3, 15)
endfunction

" augroup qf_autocmds
"   autocmd!
"   autocmd BufReadPost qf call AdjustWindow()
" augroup END

call AdjustWindows()

" call AdjustWindowHeight(5, 15)

nnoremap <buffer> q :close<CR>
