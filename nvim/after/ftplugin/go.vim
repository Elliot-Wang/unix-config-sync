if exists(':AsyncRun')
  nnoremap <buffer><silent> <F9> :<C-U>AsyncRun -mode=term -rows=10 -focus=0 time go run "%"<CR>
endif


set tabstop=2       " number of visual spaces per TAB
set softtabstop=2   " number of spaces in tab when editing
set shiftwidth=2    " number of spaces to use for autoindent
set expandtab       " expand tab to spaces so that tabs are spaces
