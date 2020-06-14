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

set laststatus=2
set noshowmode
let g:lightline = {
      \ 'colorscheme': 'jellybeans',
      \ }

" Indentation
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

" Search
set ignorecase "ic
set incsearch "is
set hlsearch
set fdo-=search

" Fold
set foldmethod=indent
set foldnestmax=4
set foldminlines=5
nnoremap <Space> za

" Splits and Tabs
set splitright
noremap <c-t> :Tex<CR>
noremap <c-w> :Vex!<CR>
noremap <c-h> <c-w>h
noremap <c-l> <c-w>l

" Basic Mappings
noremap H ^
noremap L $
noremap C :!wc<CR>
noremap <c-p> :w<CR>:!pdflatex in.tex<CR>
noremap S i$<esc>la$<esc>
noremap <c-k> <c-e>
noremap <c-j> <c-y>

autocmd Filetype javascript setlocal expandtab tabstop=2 shiftwidth=2 softtabstop=2
autocmd Filetype css setlocal expandtab tabstop=2 shiftwidth=2 softtabstop=2
autocmd Filetype html setlocal expandtab tabstop=2 shiftwidth=2 softtabstop=2
autocmd Filetype tex setlocal expandtab tabstop=2 shiftwidth=2 softtabstop=2 conceallevel=1
