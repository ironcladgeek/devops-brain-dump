" Enable syntax highlighting
syntax on

" Set line numbers
" set number

" Set tabs and indentation
set tabstop=4
set shiftwidth=4
set expandtab
set autoindent

" Enable mouse support
" set mouse=a

" Enable clipboard support
set clipboard=unnamedplus

" Highlight search results
set hlsearch

" Incremental search
set incsearch

" Enable line wrapping
set wrap

" Show matching parentheses
set showmatch

" Set color scheme
colorscheme desert

" Enable file type detection and plugins
filetype plugin indent on

" Set status line
set laststatus=2

" Enable persistent undo
set undofile

" Enable folding
set foldmethod=syntax
set foldlevelstart=99

" Set leader key
let mapleader=" "

" Basic key mappings
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
nnoremap <leader>x :x<CR>
