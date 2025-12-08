" Vim configuration with vim-plug
" ==================================

" Automatic installation of vim-plug if not installed
let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" vim-plug configuration
call plug#begin('~/.vim/plugged')

" Add vim-strudel plugin from local directory
Plug '~/vibe-producing/vim-strudel'

" Seamless navigation between vim and tmux
Plug 'christoomey/vim-tmux-navigator'

" Beautiful color schemes
Plug 'altercation/vim-colors-solarized'
Plug 'morhetz/gruvbox'

" Status line that matches tmux style
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

" Fuzzy finding
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

" Commenting support
Plug 'tpope/vim-commentary'

" Enhanced syntax highlighting for multiple languages including JSX
" Disable vim-polyglot for typescript/javascript to prevent freezing
let g:polyglot_disabled = ['typescript', 'tsx', 'javascript', 'jsx']
Plug 'sheerun/vim-polyglot'

" Lightweight TypeScript/JSX syntax highlighting
Plug 'leafgarland/typescript-vim'
Plug 'peitalin/vim-jsx-typescript'

" NERDTree - File explorer
Plug 'preservim/nerdtree'
Plug 'ryanoasis/vim-devicons'  " File icons for NERDTree
Plug 'tiagofumo/vim-nerdtree-syntax-highlight'  " Syntax highlighting for NERDTree

" You can add more plugins here in the future

call plug#end()

" Basic Vim settings
" ==================
set nocompatible              " Use Vim defaults (not Vi)
filetype plugin indent on     " Enable file type detection and plugins
syntax enable                 " Enable syntax highlighting

" User Interface
set number                    " Show line numbers
set relativenumber           " Show relative line numbers
set cursorline               " Highlight current line
set showcmd                  " Show incomplete commands
set wildmenu                 " Visual autocomplete for command menu
set lazyredraw               " Redraw only when needed
set laststatus=2             " Always show status line
set showmatch                " Highlight matching [{()}]

" Performance optimizations for large files
set synmaxcol=200            " Only syntax highlight first 200 columns
set regexpengine=1           " Use old regex engine (faster for some files)
set ttyfast                  " Assume fast terminal connection
set updatetime=300           " Faster completion

" Mouse support
set mouse=a                   " Enable mouse in all modes
if !has('nvim')
  set ttymouse=sgr           " Better mouse support for terminal
endif

" Tabs and Indentation
set tabstop=4                " Number of visual spaces per TAB
set softtabstop=0            " Disable softtabstop so backspace deletes single spaces
set shiftwidth=4             " Number of spaces for indentation
set expandtab                " Use spaces instead of tabs
set autoindent               " Auto-indent new lines
set smartindent              " Smart indentation

" Auto-format on save (commented out to prevent cursor jumping)
" autocmd BufWritePre * %s/\s\+$//e  " Remove trailing whitespace
" autocmd BufWritePre * %s/\n\+\%$//e " Remove trailing newlines

" Optional: Manual whitespace cleanup with <leader>w
nnoremap <leader>w :%s/\s\+$//e<CR>:let @/=''<CR>

" Search
set incsearch                " Search as characters are entered
set hlsearch                 " Highlight search matches
set ignorecase               " Case-insensitive search
set smartcase                " Case-sensitive if uppercase is used

" File handling
set backup                   " Keep backup files
set backupdir=~/.vim/backup  " Store backups in dedicated directory
set directory=~/.vim/swap    " Store swap files in dedicated directory
set undodir=~/.vim/undo      " Store undo files in dedicated directory
set undofile                 " Persistent undo

" Create backup directories if they don't exist
silent! call mkdir(expand('~/.vim/backup'), 'p')
silent! call mkdir(expand('~/.vim/swap'), 'p')
silent! call mkdir(expand('~/.vim/undo'), 'p')

" Key mappings
" ============
" Map leader key to space
let mapleader = " "

" Clear search highlighting with <leader><space>
nnoremap <leader><space> :nohlsearch<CR>

" Quick escape with jj in insert mode
inoremap jj <ESC>

" Vim-tmux-navigator with Ctrl+hjkl (this is the default)
" No need to disable mappings, we want the default Ctrl behavior
let g:tmux_navigator_no_mappings = 0

" The plugin automatically sets up these mappings:
" nnoremap <silent> <C-h> :TmuxNavigateLeft<cr>
" nnoremap <silent> <C-j> :TmuxNavigateDown<cr>
" nnoremap <silent> <C-k> :TmuxNavigateUp<cr>
" nnoremap <silent> <C-l> :TmuxNavigateRight<cr>

" Also keep simple vim-only navigation as fallback with leader
nnoremap <leader>h <C-w>h
nnoremap <leader>j <C-w>j
nnoremap <leader>k <C-w>k
nnoremap <leader>l <C-w>l

" Map Shift+K and Shift+J to go to first and last line
nnoremap K gg
nnoremap J G

" Shift+Tab for untab (dedent) in insert and visual modes
inoremap <S-Tab> <C-d>
vnoremap <S-Tab> <gv
vnoremap <Tab> >gv

" Tab to jump to matching bracket/parenthesis
" In normal mode, Tab jumps to matching bracket
nnoremap <Tab> %
" In visual mode, Tab jumps to matching bracket and selects the range
vnoremap <Tab> %

" Optional: Use Tab in insert mode to jump out of brackets
" This will jump past the next closing bracket/paren/brace
inoremap <expr> <Tab> search('\%#[]>)}]', 'n') ? '<Right>' : '<Tab>'

" Commentary plugin mappings
" Most reliable: use gc commands directly without trying Ctrl
" Select text in visual mode, then type gc to comment
" In normal mode, gcc comments current line

" Simple comma mapping that definitely works
nnoremap ,/ gcc
vnoremap ,/ gc

" Double comma for easy access  
nnoremap ,, gcc
vnoremap ,, gc

" Also keep ,c
nmap ,c gcc
vmap ,c gc

" Map Cmd+/ (D-/) to trigger commenting in all modes
" Note: This only works in MacVim or GUI vim, not in terminal vim
if has('gui_running') || has('macunix')
  " Normal mode: comment current line
  nnoremap <D-/> gcc
  " Visual mode: comment selection
  vnoremap <D-/> gc
  " Insert mode: exit insert, comment line, return to insert at end
  inoremap <D-/> <Esc>gcc$a
endif

" For terminal vim on Mac, we can try to capture Cmd+/ but it's often intercepted
" Alternative: Use Ctrl+/ which works in terminal
nnoremap <C-_> gcc
vnoremap <C-_> gc
inoremap <C-_> <Esc>gcc$a

" FZF key mappings
" Ctrl+P for fuzzy file search in current directory
nnoremap <C-p> :Files<CR>

" ,f for fuzzy string search across files (using ripgrep)
nnoremap ,f :Rg<CR>

" NERDTree mappings and configuration
" ===================================
" Toggle NERDTree with Ctrl+n
nnoremap <C-n> :NERDTreeToggle<CR>

" Find current file in NERDTree with ,n
nnoremap ,n :NERDTreeFind<CR>

" NERDTree settings
let g:NERDTreeShowHidden = 1                " Show hidden files
let g:NERDTreeIgnore = ['\.git$', '\.DS_Store$', '\.swp$', '\.swo$', 'node_modules$', '__pycache__$', '\.pyc$']
let g:NERDTreeWinSize = 30                  " Set width
let g:NERDTreeMinimalUI = 1                 " Remove help text
let g:NERDTreeDirArrows = 1                 " Use arrows for directories
let g:NERDTreeAutoDeleteBuffer = 1          " Auto delete buffer of deleted file
let g:NERDTreeQuitOnOpen = 0                " Keep NERDTree open after opening file
let g:NERDTreeShowLineNumbers = 0           " Don't show line numbers in NERDTree
let g:NERDTreeMouseMode = 2                 " Single click to open directories
let g:NERDTreeNaturalSort = 1               " Natural sorting (10 after 9, not after 1)

" Open NERDTree automatically when vim starts with a directory
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 1 && isdirectory(argv()[0]) && !exists("s:std_in") | exe 'NERDTree' argv()[0] | wincmd p | ene | exe 'cd '.argv()[0] | endif

" Close vim if NERDTree is the only window left
autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | quit | endif

" NERDTree custom mappings (when NERDTree is focused)
" These work inside NERDTree buffer
let g:NERDTreeMapOpenSplit = 's'           " s to open in horizontal split
let g:NERDTreeMapOpenVSplit = 'v'          " v to open in vertical split
let g:NERDTreeMapOpenInTab = 't'           " t to open in new tab
let g:NERDTreeMapPreview = 'go'            " go to preview file
let g:NERDTreeMapActivateNode = '<CR>'     " Enter to open file/directory
let g:NERDTreeMapCloseDir = 'x'            " x to close directory
let g:NERDTreeMapCloseChildren = 'X'       " X to close all child directories recursively
let g:NERDTreeMapRefresh = 'r'             " r to refresh
let g:NERDTreeMapRefreshRoot = 'R'         " R to refresh root
let g:NERDTreeMapHelp = '?'                " ? for help

" vim-strudel specific settings
" =============================
" These will be available after the plugin is loaded
" You can add custom mappings or settings for Strudel files here

" Override Strudel plugin's tab settings to use 4 spaces
autocmd FileType strudel setlocal tabstop=4 shiftwidth=4 softtabstop=4

" JSX/TSX specific settings to prevent freezing
" =============================================
" Disable some heavy features for JSX/TSX files
autocmd BufEnter *.jsx,*.tsx setlocal synmaxcol=120
autocmd BufEnter *.jsx,*.tsx setlocal nocursorline
autocmd BufEnter *.jsx,*.tsx setlocal norelativenumber

" Use 2 spaces for JS/TS files (common convention)
autocmd FileType javascript,javascriptreact,typescript,typescriptreact setlocal tabstop=2 shiftwidth=2 softtabstop=2

" Disable syntax highlighting for very large files
autocmd BufReadPre * if getfsize(expand("%")) > 10000000 | syntax off | endif

" Color scheme and visual settings
" =================================
" Enable true colors if available
if has('termguicolors')
  set termguicolors
endif

" Choose color scheme (comment/uncomment to switch)
set background=dark

" Option 1: Solarized
" let g:solarized_termcolors=256
" silent! colorscheme solarized

" Option 2: Gruvbox (recommended - looks great)
let g:gruvbox_contrast_dark = 'medium'
let g:gruvbox_improved_strings = 1
let g:gruvbox_improved_warnings = 1
silent! colorscheme gruvbox

" Fallback if colorscheme not installed yet
if !exists('g:colors_name')
  colorscheme desert
endif

" Airline configuration
let g:airline_theme = 'gruvbox'  " or 'solarized' if using solarized
let g:airline_powerline_fonts = 0
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#formatter = 'unique_tail'

" Simplify airline to avoid clutter
if !exists('g:airline_symbols')
  let g:airline_symbols = {}
endif
let g:airline_left_sep = ''
let g:airline_right_sep = ''
let g:airline_symbols.branch = ''
let g:airline_symbols.readonly = ''
let g:airline_symbols.linenr = '☰'
let g:airline_symbols.maxlinenr = ''

" Visual improvements
set fillchars=vert:│,fold:─    " Better vertical split character
set listchars=tab:→\ ,trail:·,extends:›,precedes:‹
set signcolumn=yes              " Always show sign column
set colorcolumn=80,120          " Show column guides

" Make splits more visible
hi VertSplit cterm=NONE

" Better popup menu colors (for autocomplete)
hi Pmenu ctermfg=15 ctermbg=0 guifg=#ffffff guibg=#000000
hi PmenuSel ctermfg=0 ctermbg=3 guifg=#000000 guibg=#808000