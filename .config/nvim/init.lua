-- Neovim configuration focused on Rust / TypeScript / Python
-- Keeps your existing keymaps, drops AI bindings, adds modern LSP + inlay hints

-- Leader
vim.g.mapleader = ","
vim.g.maplocalleader = ","

-- Basic options
local opt = vim.opt
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.showmatch = true
opt.termguicolors = true
opt.updatetime = 300
opt.signcolumn = "yes"
opt.colorcolumn = "80,120"
opt.wrap = false
opt.mouse = "a"
opt.splitbelow = true
opt.splitright = true
opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.smartindent = true
opt.autoindent = true
opt.completeopt = { "menu", "menuone", "noselect" }
opt.autoread = true
opt.shortmess:append("A") -- no ATTENTION prompts

-- Auto-reload files changed on disk without prompting
vim.api.nvim_create_augroup("AutoRead", { clear = true })
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
  group = "AutoRead",
  command = "silent! checktime",
})
vim.api.nvim_create_autocmd("BufWritePre", {
  group = "AutoRead",
  command = "silent! checktime",
})
vim.api.nvim_create_autocmd("FileChangedShellPost", {
  group = "AutoRead",
  command = 'echohl WarningMsg | echo "File changed on disk. Buffer reloaded." | echohl None',
})

-- Filetype specific
local ft_group = vim.api.nvim_create_augroup("UserFiletypes", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  group = ft_group,
  pattern = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.softtabstop = 2
  end,
})
vim.api.nvim_create_autocmd("BufEnter", {
  group = ft_group,
  pattern = { "*.jsx", "*.tsx" },
  callback = function()
    vim.opt_local.synmaxcol = 120
    vim.opt_local.cursorline = false
    vim.opt_local.relativenumber = false
  end,
})
vim.api.nvim_create_autocmd("FileType", {
  group = ft_group,
  pattern = "strudel",
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.softtabstop = 4
  end,
})

-- Keymaps (mirrors most of your old vimrc, no AI bindings)
local map = vim.keymap.set
local silent = { silent = true }
map("n", "<leader><space>", ":nohlsearch<CR>", silent)
map("i", "jj", "<Esc>", silent)
map("n", "<leader>h", "<C-w>h", silent)
map("n", "<leader>j", "<C-w>j", silent)
map("n", "<leader>k", "<C-w>k", silent)
map("n", "<leader>l", "<C-w>l", silent)
map("n", "K", "gg", silent)
map("n", "J", "G", silent)
map("n", "<Tab>", "%", silent)
map("v", "<Tab>", "%", silent)
map("i", "<S-Tab>", "<C-d>", silent)
map("v", "<S-Tab>", "<gv", silent)
map("n", "<C-n>", ":NvimTreeToggle<CR>", silent)
map("n", ",n", ":NvimTreeFindFile<CR>", silent)
map("n", "<C-p>", ":Telescope find_files<CR>", silent)
map("n", ",f", ":Telescope live_grep<CR>", silent)
map("n", ",/", function()
  vim.cmd("Commentary")
end, silent)
map("v", ",/", ":Commentary<CR>", silent)
map("n", ",,", function()
  vim.cmd("Commentary")
end, silent)
map("v", ",,", ":Commentary<CR>", silent)
map("n", ",c", function()
  vim.cmd("Commentary")
end, silent)
map("v", ",c", ":Commentary<CR>", silent)
-- Keep Ctrl-hjkl navigator (handled by vim-tmux-navigator plugin)

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

-- Plugins
require("lazy").setup({
  -- Colors
  {
    "ellisonleao/gruvbox.nvim",
    priority = 1000,
    config = function()
      require("gruvbox").setup({ contrast = "medium" })
      vim.cmd("colorscheme gruvbox")
    end,
  },

  -- Statusline
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({ options = { theme = "gruvbox", icons_enabled = true } })
    end,
  },

  -- File tree
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("nvim-tree").setup({
        respect_buf_cwd = true,
        update_focused_file = { enable = true, update_root = true },
        view = { width = 30 },
        renderer = { icons = { git_placement = "after" } },
      })
    end,
  },

  -- Telescope (fuzzy finder)
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("telescope").setup({ defaults = { layout_config = { width = 0.9 } } })
    end,
  },

  -- Comment toggles (keeps your ,/, ,, mappings)
  { "tpope/vim-commentary" },

  -- Treesitter for better syntax
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "lua",
          "rust",
          "toml",
          "vim",
          "vimdoc",
          "javascript",
          "typescript",
          "tsx",
          "json",
          "python",
          "yaml",
          "markdown",
        },
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },

  -- LSP + tooling
  { "williamboman/mason.nvim", build = ":MasonUpdate" },
  { "hrsh7th/nvim-cmp" },
  { "hrsh7th/cmp-nvim-lsp" },
  { "hrsh7th/cmp-buffer" },
  { "hrsh7th/cmp-path" },
  { "saadparwaiz1/cmp_luasnip" },
  { "L3MON4D3/LuaSnip" },
  { "rafamadriz/friendly-snippets" },
  { "windwp/nvim-autopairs", config = function() require("nvim-autopairs").setup() end },
  { "lewis6991/gitsigns.nvim", config = function() require("gitsigns").setup() end },
  { "christoomey/vim-tmux-navigator" },
  { "folke/trouble.nvim", dependencies = { "nvim-tree/nvim-web-devicons" } },
  { "stevearc/conform.nvim" },
  { "ray-x/lsp_signature.nvim" },
  { "stevearc/dressing.nvim" },

  -- Local Strudel plugin
  { dir = "~/vibe-producing/vim-strudel" },
}, {
  install = { colorscheme = { "gruvbox" } },
})

-- Completion setup
local cmp = require("cmp")
local luasnip = require("luasnip")
require("luasnip.loaders.from_vscode").lazy_load()

local function has_words_before()
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  return col ~= 0 and vim.api.nvim_buf_get_text(0, line - 1, col - 1, line - 1, col, {})[1]:match("%s") == nil
end

cmp.setup({
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  completion = {
    autocomplete = { "InsertEnter", "TextChanged" }, -- pop up as you type
  },
  mapping = cmp.mapping.preset.insert({
    ["<C-n>"] = cmp.mapping.select_next_item(),
    ["<C-p>"] = cmp.mapping.select_prev_item(),
    ["<C-d>"] = cmp.mapping.scroll_docs(4),
    ["<C-u>"] = cmp.mapping.scroll_docs(-4),
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<CR>"] = cmp.mapping.confirm({ select = true }),
    ["<C-e>"] = cmp.mapping.abort(),
    ["<Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      elseif has_words_before() then
        cmp.complete()
      else
        fallback()
      end
    end, { "i", "s" }),
    ["<S-Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { "i", "s" }),
  }),
  sources = cmp.config.sources({
    { name = "nvim_lsp" },
    { name = "path" },
    { name = "buffer" },
  }),
})

-- Autopairs integration with cmp
local cmp_autopairs = require("nvim-autopairs.completion.cmp")
cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())

-- LSP configuration
require("mason").setup()

local capabilities = require("cmp_nvim_lsp").default_capabilities()

local function set_inlay_hints(bufnr)
  if vim.lsp.inlay_hint and vim.lsp.inlay_hint.enable then
    pcall(vim.lsp.inlay_hint.enable, true, { bufnr = bufnr })
  end
end

local on_attach = function(client, bufnr)
  local bufmap = function(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
  end
  bufmap("n", "gd", vim.lsp.buf.definition, "Go to definition")
  bufmap("n", "gr", vim.lsp.buf.references, "References")
  bufmap("n", "gi", vim.lsp.buf.implementation, "Go to implementation")
  bufmap("n", "gh", vim.lsp.buf.hover, "Hover")
  bufmap("n", "<leader>rn", vim.lsp.buf.rename, "Rename symbol")
  bufmap("n", "<leader>ca", vim.lsp.buf.code_action, "Code action")
  bufmap("n", "<leader>f", function() vim.lsp.buf.format({ async = true }) end, "Format")
  bufmap("n", "[d", vim.diagnostic.goto_prev, "Prev diagnostic")
  bufmap("n", "]d", vim.diagnostic.goto_next, "Next diagnostic")
  bufmap("n", "gl", vim.diagnostic.open_float, "Line diagnostics")
  set_inlay_hints(bufnr)
end

-- Helpers for native vim.lsp.start
local function bin(name)
  local rustup = vim.fn.expand("~/.cargo/bin/" .. name)
  if vim.uv.fs_stat(rustup) then
    return rustup
  end
  local mason = vim.fn.stdpath("data") .. "/mason/bin/" .. name
  if vim.uv.fs_stat(mason) then
    return mason
  end
  return vim.fn.exepath(name)
end

local function path_exists(p)
  return p and vim.uv.fs_stat(p) ~= nil
end

-- Build a GitHub link to the current file+line (or visual range) at HEAD and copy to clipboard
local function copy_github_link()
  local buf = vim.api.nvim_get_current_buf()
  local file = vim.api.nvim_buf_get_name(buf)
  if file == "" then
    vim.notify("No file for buffer", vim.log.levels.WARN)
    return
  end
  local file_dir = vim.fn.fnamemodify(file, ":h")
  local function git(args)
    local out = vim.fn.systemlist({ "git", "-C", file_dir, unpack(args) })
    if vim.v.shell_error ~= 0 then return nil end
    return out[1]
  end
  local root = git({ "rev-parse", "--show-toplevel" })
  local remote = git({ "config", "--get", "remote.origin.url" })
  local commit = git({ "rev-parse", "HEAD" })
  if not (root and remote and commit) then
    vim.notify("Not a git repo or remote/HEAD missing", vim.log.levels.WARN)
    return
  end

  -- Normalize remote to https://github.com/user/repo
  local url = remote
  if url:match("^git@") then
    url = url:gsub(":", "/"):gsub("^git@", "https://")
  elseif url:match("^https?://") then
    -- keep
  else
    vim.notify("Unsupported remote: " .. url, vim.log.levels.WARN)
    return
  end
  url = url:gsub("%.git$", "")

  local rel = file:sub(#root + 2) -- remove root and slash

  local mode = vim.fn.mode()
  local l1, l2
  if mode == "v" or mode == "V" or mode == "\22" then
    local start = vim.fn.getpos("v")[2]
    local finish = vim.fn.getpos(".")[2]
    l1, l2 = math.min(start, finish), math.max(start, finish)
  else
    l1 = vim.api.nvim_win_get_cursor(0)[1]
  end

  local anchor = "#L" .. l1
  if l2 and l2 ~= l1 then anchor = anchor .. "-L" .. l2 end

  local final = string.format("%s/blob/%s/%s%s", url, commit, rel, anchor)
  vim.fn.setreg("+", final)
  vim.fn.setreg("*", final)
  vim.notify("Copied link: " .. final, vim.log.levels.INFO)
end

local function find_venv(startpath)
  local function check_dir(dir)
    for _, name in ipairs({ ".venv", "venv", ".env", "env" }) do
      local root = dir .. "/" .. name
      if path_exists(root .. "/bin/python") then
        return {
          venv_path = root,
          bin = root .. "/bin",
          name = name,
        }
      end
    end
    return nil
  end

  local dir = startpath ~= "" and startpath or vim.uv.cwd()
  -- check current dir
  local v = check_dir(dir)
  if v then return v end
  -- walk parents
  for parent in vim.fs.parents(dir) do
    v = check_dir(parent)
    if v then return v end
  end
  return nil
end

local function root_dir(patterns, fname)
  fname = fname ~= "" and fname or vim.uv.cwd()
  local found = vim.fs.find(patterns, { path = vim.fs.dirname(fname), upward = true })[1]
  return found and vim.fs.dirname(found) or vim.uv.cwd()
end

local function start_server(cfg)
  cfg.capabilities = capabilities
  local orig_on_attach = cfg.on_attach
  cfg.on_attach = function(client, bufnr)
    on_attach(client, bufnr)
    if orig_on_attach then orig_on_attach(client, bufnr) end
  end
  cfg.reuse_client = function(client, conf)
    return client.name == conf.name and client.config.root_dir == conf.root_dir
  end
  vim.lsp.start(cfg)
end

local lsp_group = vim.api.nvim_create_augroup("UserLspNative", { clear = true })

-- Rust
vim.api.nvim_create_autocmd("FileType", {
  group = lsp_group,
  pattern = "rust",
  callback = function(args)
    local fname = vim.api.nvim_buf_get_name(args.buf)
    start_server({
      name = "rust_analyzer",
      cmd = { bin("rust-analyzer") },
      root_dir = root_dir({ "Cargo.toml", "rust-project.json", ".git" }, fname),
      settings = {
        ["rust-analyzer"] = {
          cargo = { allFeatures = true },
          check = { command = "clippy" },
          inlayHints = {
            enable = true,
            bindingModeHints = true,
            chainingHints = true,
            closingBraceHints = { enable = true, minLines = 0 },
            expressionAdjustmentHints = { enable = "always" },
            lifetimeElisionHints = { enable = "always", useParameterNames = true },
            parameterHints = true,
            reborrowHints = true,
            typeHints = true,
          },
        },
      },
    })
  end,
})

-- TypeScript / JavaScript
vim.api.nvim_create_autocmd("FileType", {
  group = lsp_group,
  pattern = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
  callback = function(args)
    local fname = vim.api.nvim_buf_get_name(args.buf)
    start_server({
      name = "ts_ls",
      cmd = { bin("typescript-language-server"), "--stdio" },
      root_dir = root_dir({ "tsconfig.json", "jsconfig.json", "package.json", ".git" }, fname),
      init_options = {
        preferences = {
          includeInlayParameterNameHints = "all",
          includeInlayParameterNameHintsWhenArgumentMatchesName = false,
          includeInlayFunctionParameterTypeHints = true,
          includeInlayVariableTypeHints = true,
          includeInlayPropertyDeclarationTypeHints = true,
          includeInlayFunctionLikeReturnTypeHints = true,
          includeInlayEnumMemberValueHints = true,
        },
        inlayHints = { includeInlayEnumMemberValueHints = true, includeInlayFunctionLikeReturnTypeHints = true },
      },
    })
  end,
})

-- Python
vim.api.nvim_create_autocmd("FileType", {
  group = lsp_group,
  pattern = "python",
  callback = function(args)
    local fname = vim.api.nvim_buf_get_name(args.buf)
    local startdir = vim.fs.dirname(fname ~= "" and fname or vim.uv.cwd())
    local project_root = root_dir({ "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", ".git" }, fname)
    local venv = find_venv(startdir)
    if not venv then
      -- if uv is available, try to bootstrap a venv in the project root
      local uv_bin = bin("uv")
      if uv_bin and uv_bin ~= "" then
        vim.fn.system({ uv_bin, "venv" }, project_root)
        venv = find_venv(project_root)
      end
    end
    local cmd_env = nil
    local pysettings = {
      analysis = {
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
        typeCheckingMode = "basic",
        inlayHints = {
          variableTypes = true,
          functionReturnTypes = true,
          callArgumentNames = "all",
          parameterNames = "all",
          parameterTypes = true,
        },
      },
    }
    if venv then
      cmd_env = {
        PATH = venv.bin .. ":" .. vim.env.PATH,
        VIRTUAL_ENV = venv.venv_path,
      }
      pysettings.venvPath = vim.fs.dirname(venv.venv_path)
      pysettings.venv = vim.fs.basename(venv.venv_path)
    end
    start_server({
      name = "basedpyright",
      cmd = { (bin("basedpyright-langserver") ~= "" and bin("basedpyright-langserver") or bin("pyright-langserver")), "--stdio" },
      root_dir = project_root,
      settings = { python = pysettings },
      cmd_env = cmd_env,
    })
  end,
})

-- Lua (this config)
vim.api.nvim_create_autocmd("FileType", {
  group = lsp_group,
  pattern = "lua",
  callback = function(args)
    local fname = vim.api.nvim_buf_get_name(args.buf)
    start_server({
      name = "lua_ls",
      cmd = { bin("lua-language-server") },
      root_dir = root_dir({ ".git" }, fname),
      settings = {
        Lua = {
          diagnostics = { globals = { "vim" } },
          workspace = { checkThirdParty = false },
        },
      },
    })
  end,
})

-- Conform (formatting) - format on save for the common stacks
require("conform").setup({
  format_on_save = function(bufnr)
    local ft = vim.bo[bufnr].filetype
    if ft == "rust" or ft == "python" or ft == "javascript" or ft == "typescript" or ft == "typescriptreact" then
      return { timeout_ms = 4000, lsp_fallback = false }
    end
    return nil
  end,
  formatters_by_ft = {
    rust = { "cargo_nightly_fmt" },
    javascript = { "prettier" },
    typescript = { "prettier" },
    typescriptreact = { "prettier" },
    python = { "uv_format" },
  },
  formatters = {
    cargo_nightly_fmt = {
      command = "cargo",
      args = { "+nightly", "fmt" },
      stdin = false, -- format files in place
      cwd = function(ctx)
        return root_dir({ "Cargo.toml" }, ctx.filename) or root_dir({ ".git" }, ctx.filename) or vim.fn.getcwd()
      end,
    },
    uv_format = {
      command = "uv",
      args = { "format", "--preview-features", "format" },
      stdin = false, -- uv formats in place; avoid piping buffer through stdout
      cwd = function(ctx)
        return root_dir({ "pyproject.toml", "requirements.txt" }, ctx.filename) or root_dir({ ".git" }, ctx.filename) or vim.fn.getcwd()
      end,
    },
  },
})

-- Trouble (diagnostics list)
require("trouble").setup({})

-- Signature help
require("lsp_signature").setup({ hint_enable = false, handler_opts = { border = "rounded" } })

-- Diagnostics look
vim.diagnostic.config({
  virtual_text = true,
  signs = true,
  update_in_insert = false,
  severity_sort = true,
})

-- Make inlay hints visible
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("InlayHintStyle", { clear = true }),
  callback = function()
    vim.api.nvim_set_hl(0, "LspInlayHint", { fg = "#928374", bg = "NONE", italic = true })
  end,
})
vim.api.nvim_set_hl(0, "LspInlayHint", { fg = "#928374", bg = "NONE", italic = true })

-- Preserve colorcolumn guide in current buffer as soon as a file opens
vim.api.nvim_create_autocmd("BufEnter", {
  group = vim.api.nvim_create_augroup("ColorColumn", { clear = true }),
  callback = function()
    vim.opt_local.colorcolumn = "80,120"
  end,
})

-- Use Gruvbox background dark by default
vim.o.background = "dark"

-- Quick keymaps for LSP niceties
local map = vim.keymap.set
map("n", "<leader>ih", function()
  if vim.lsp.inlay_hint and vim.lsp.inlay_hint.is_enabled then
    local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = 0 })
    vim.lsp.inlay_hint.enable(not enabled, { bufnr = 0 })
  end
end, { silent = true, desc = "Toggle inlay hints" })
map("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", { silent = true, desc = "Trouble diagnostics" })
map("n", "<leader>xw", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", { silent = true, desc = "Trouble workspace diag" })
map("n", "<leader>q", function() vim.diagnostic.setloclist() end, { silent = true, desc = "Diagnostics to loclist" })

-- Jump list navigation on leader
map("n", "<leader>[", "<C-o>", { silent = true, desc = "Jump back" })
map("n", "<leader>]", "<C-i>", { silent = true, desc = "Jump forward" })
map({ "n", "v" }, "<leader>gy", copy_github_link, { silent = true, desc = "Copy GitHub link to line/range" })
