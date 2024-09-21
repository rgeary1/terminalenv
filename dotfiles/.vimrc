noremap q :q<cr>
noremap <C-q> :q<cr>
noremap <C-s> :w<cr>
inoremap <C-q> <esc>:q<cr>
inoremap <C-s> <esc>:w<cr>
vnoremap <C-q> <esc>:q<cr>
vnoremap <C-s> <esc>:w<cr>
" Ctrl del
inoremap <esc>[3;5~ <C-o>de
noremap <esc>[3;5~ de
" Ctrl Backspace
inoremap <C-BS> <C-W>
noremap <C-BS> db
set expandtab
set tabstop=2
set number 
noremap n :set number!<cr>
