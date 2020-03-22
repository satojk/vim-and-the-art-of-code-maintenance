" Essentials
syntax enable

set number
set relativenumber
set ruler
set cursorline

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
