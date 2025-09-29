" Disable inserting comment leader after hitting o or O or <Enter>
set formatoptions-=o
set formatoptions-=r

if exists(':AsyncRun')
  nnoremap <buffer><silent> <F9> :<C-U>AsyncRun -mode=term -rows=10 -focus=0 time node "%"<CR>
endif
