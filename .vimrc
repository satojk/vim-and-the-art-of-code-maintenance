" BEGIN VUNDLE SETUP

set nocompatible              " be iMproved, required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'
Plugin 'itchyny/lightline.vim'

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

" END OF VUNDLE SETUP

" Essentials
syntax enable

set number
set relativenumber
set ruler
set cursorline

color onedark

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
:command FI set foldmethod=indent
:command FM set foldmethod=manual
nnoremap <Space> za

" Basic Mappings
noremap H ^
noremap L $
noremap C :!wc<CR>

autocmd Filetype javascript setlocal expandtab tabstop=2 shiftwidth=2 softtabstop=2
autocmd Filetype css setlocal expandtab tabstop=2 shiftwidth=2 softtabstop=2
autocmd Filetype html setlocal expandtab tabstop=2 shiftwidth=2 softtabstop=2
autocmd Filetype latex setlocal expandtab tabstop=2 shiftwidth=2 softtabstop=2
