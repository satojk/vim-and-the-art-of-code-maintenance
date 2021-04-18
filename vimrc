" Begin Vundle setup

set nocompatible              " be iMproved, required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'

Plugin 'mhartington/oceanic-next'

Plugin 'itchyny/lightline.vim'

Plugin 'lervag/vimtex'
let g:tex_flavor='latex'
let g:tex_conceal='abdmg'

Plugin 'majutsushi/tagbar'
nnoremap T :TagbarOpenAutoClose<CR>

Plugin 'preservim/nerdcommenter'
let g:NERDCreateDefaultMappings=0

Plugin 'rhysd/clever-f.vim'
let g:clever_f_smart_case=1
let g:NERDToggleCheckAllLines = 1
let g:NERDSpaceDelims = 1

"Plugin 'SirVer/ultisnips'
"Plugin 'honza/vim-snippets'
"let g:UltiSnipsExpandTrigger="<tab>"
"let g:UltiSnipsJumpForwardTrigger="<c-b>"
"let g:UltiSnipsJumpBackwardTrigger="<c-z>"

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required
" To ignore plugin indent changes, instead use:
"filetype plugin on
"
" Brief help
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
"
" see :h vundle for more details or wiki for FAQ
" Put your non-Plugin stuff after this line

" End Vundle setup


" Essentials
syntax enable

colorscheme OceanicNext

set number
set relativenumber
set ruler
set cursorline
set scrolloff=7

set laststatus=2
set noshowmode
let g:lightline = {
      \ 'colorscheme': 'jellybeans',
      \ }

set list
set listchars=tab:!·,trail:·

set showcmd

set expandtab
set shiftwidth=4
set softtabstop=4
set smartindent
set cindent
set cinkeys-=0#
set indentkeys-=0#

" Wrap
set formatoptions+=w
set tw=79
set colorcolumn=80

" Search
nnoremap / /\v
set ignorecase
set smartcase
set gdefault
set incsearch
set hlsearch
set fdo-=search

" Autocomplete
setglobal complete=.

" Fold
set foldmethod=indent
set foldnestmax=4
set foldminlines=3
map <Space> za

" Splits and Tabs
set splitright
noremap <c-t> :Tex<CR>
noremap <c-w> :Vex!<CR>
noremap <c-h> <c-w>h
noremap <c-l> <c-w>l

" Basic Mappings
noremap H ^
noremap L $
noremap <tab> %
noremap <c-k> <c-e>
noremap <c-j> <c-y>
nnoremap ; :
nnoremap U <c-r>
nnoremap C :!wc<CR>
nnoremap <c-p> :w<CR>:!pdflatex in.tex<CR>
nnoremap S i$<esc>la$<esc>
nnoremap <c-r> <esc>:source $MYVIMRC<CR>
noremap Y "+y
noremap P "+p

" Leader Mappings
noremap , <Nop>
let mapleader=','

nnoremap <leader>clw <esc>:%s/\s\+$//<CR>:let @/=''<CR><c-o>
nnoremap <leader>sub <esc>:%s/
nnoremap <leader>n <esc>:noh<CR>
nmap <leader>cc <plug>NERDCommenterInvert


autocmd Filetype javascript setlocal expandtab tabstop=2 shiftwidth=2 softtabstop=2
autocmd Filetype js setlocal expandtab tabstop=2 shiftwidth=2 softtabstop=2
autocmd Filetype css setlocal expandtab tabstop=2 shiftwidth=2 softtabstop=2
autocmd Filetype html setlocal expandtab tabstop=2 shiftwidth=2 softtabstop=2
autocmd Filetype tex setlocal expandtab tabstop=2 shiftwidth=2 softtabstop=2 conceallevel=1
autocmd BufNewFile,BufRead *.tt set syntax=cpp
autocmd BufNewFile,BufRead *.genie set syntax=javascript
autocmd BufNewFile,BufRead *.pegjs set syntax=javascript
