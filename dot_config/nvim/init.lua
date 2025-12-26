-- ~/.config/nvim/init.lua
-- ---------------------------------------------------------------------------
-- Minimal Neovim configuration
-- - No plugins
-- - Just sane defaults for editing, search, splits, undo, etc.
-- - Designed to be a good base for later adding plugins (LSP, tree, etc.)
-- ---------------------------------------------------------------------------

-----------------------------
-- Leader key
-----------------------------
-- <Space> will be the "leader" for custom mappings later, e.g. <Space>ff
vim.g.mapleader = " "

-----------------------------
-- Line numbers
-----------------------------
local opt = vim.opt
local fn  = vim.fn

-- Show absolute line number on the current line and relative numbers elsewhere.
-- This makes motions like `5j` or `3k` much easier to reason about.
opt.number         = true
opt.relativenumber = true

-----------------------------
-- Indentation
-----------------------------
-- These are "Python-friendly" defaults; change 4 → 2 if you prefer 2-space indents.
opt.tabstop     = 4    -- how many spaces a <Tab> counts for
opt.shiftwidth  = 4    -- how many spaces to use for each step of (auto)indent
opt.expandtab   = true -- insert spaces instead of <Tab> characters
opt.autoindent  = true -- copy indent from current line when starting a new one
opt.smartindent = true -- try to be smart about indentation in some languages

-----------------------------
-- Search
-----------------------------
opt.ignorecase = true  -- case-insensitive search by default…
opt.smartcase  = true  -- …but if the pattern has a capital letter, make it case-sensitive
opt.incsearch  = true  -- show matches as you type the search

-----------------------------
-- Appearance / layout
-----------------------------
opt.termguicolors = true   -- enable truecolor support in the terminal
opt.signcolumn    = "yes"  -- always reserve space for signs (git, diagnostics, etc.)

-- Draw a vertical guide at column 80 (common width for Python / text).
-- Adjust to 88/100/120 if your style uses wider lines.
opt.colorcolumn = "160"

-----------------------------
-- Clipboard
-----------------------------
-- Use the system clipboard for all yank/cut/copy operations.
-- This makes Neovim behave more like a GUI editor (Cmd+C / Cmd+V style).
opt.clipboard:append("unnamedplus")

-----------------------------
-- Backspace behavior
-----------------------------
-- Make <Backspace> in insert mode behave like most editors:
-- it can cross indentation, end-of-line, and the point where insert mode started.
opt.backspace = "indent,eol,start"

-----------------------------
-- Window splitting
-----------------------------
-- When splitting, put new windows below / to the right (VS Code-style).
opt.splitbelow = true
opt.splitright = true

-----------------------------
-- Word motions (`w`, `b`, etc.)
-----------------------------
-- Treat `-` as part of a word. So `dw` on `some-name` deletes the whole thing.
-- This is often more convenient for code and prose.
opt.iskeyword:append("-")

-----------------------------
-- Scrolling
-----------------------------
-- Keep some context above/below the cursor when scrolling.
-- 8 feels nice on a reasonably tall terminal; lower it if you want more space.
opt.scrolloff = 8

-----------------------------
-- Undo history / swap / backup
-----------------------------
-- Don't create backup or swap files; use persistent undo instead.
opt.swapfile = false
opt.backup   = false

-- Store undo history in a dedicated directory so it persists across sessions.
-- This is a Vim-style path; you can change it if you prefer a different location.
local undodir = fn.expand("~/.vim/undodir")
fn.mkdir(undodir, "p")    -- create the directory if it doesn't exist
opt.undodir  = undodir
opt.undofile = true       -- actually enable persistent undo

-----------------------------
-- Performance / responsiveness
-----------------------------
-- Decrease the time before CursorHold events / diagnostics / etc. trigger.
-- Default is 4000ms; 250ms feels responsive without being too chatty.
opt.updatetime = 250

-- =======================================================================
-- lazy.nvim plugin manager (single-file setup, per official docs)
-- =======================================================================

-- Bootstrap lazy.nvim: clone it to stdpath("data")/lazy/lazy.nvim if needed.
local lazypath = fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = fn.system({ "git", "clone", "--filter=blob:none",
    "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    fn.getchar()
    os.exit(1)
  end
end
opt.rtp:prepend(lazypath)

-- Local leader (you can change this later if you care)
vim.g.maplocalleader = "\\"

require("lazy").setup({
  spec = {
    -- Sonokai colorscheme
    {
      "sainnhe/sonokai",
      lazy = false,      -- load during startup
      priority = 1000,   -- load before other UI plugins
      config = function()
        -- Choose one of: "default", "atlantis", "andromeda", "shusia", "maia", "espresso"
        vim.g.sonokai_style = "andromeda"

        -- Minor perf tweak recommended by the author
        vim.g.sonokai_better_performance = 1

        -- If you ever want italics:
        -- vim.g.sonokai_enable_italic = true

        -- Apply the colorscheme
        vim.cmd.colorscheme("sonokai")
      end,
    },
    -- Telescope: fuzzy finder (files, grep, buffers)
    {
      "nvim-telescope/telescope.nvim",
      dependencies = { "nvim-lua/plenary.nvim" },
      config = function()
        local builtin = require("telescope.builtin")

        -- Find files in current project (like VS Code "Go to file")
        vim.keymap.set("n", "<leader>ff", builtin.find_files, {
          desc = "Telescope: find files",
        })

        -- Live grep in project (like VS Code "Search in files")
        vim.keymap.set("n", "<leader>fg", builtin.live_grep, {
          desc = "Telescope: live grep",
        })

        -- Switch open buffers
        vim.keymap.set("n", "<leader>fb", builtin.buffers, {
          desc = "Telescope: buffers",
        })
        vim.keymap.set("n", "<leader>fh", builtin.help_tags, { 
	  desc = "Telescope help tags",
        })
      end,
    },
    -- Treesitter: better syntax highlighting / indentation
    {
      "nvim-treesitter/nvim-treesitter",
      lazy = false,
      build = ":TSUpdate",
    },
  },

  install = {
    -- fallback colorscheme used *only* while installing plugins
    colorscheme = { "habamax" },
  },

  checker = { enabled = true },

  -- Optional: we don't use LuaRocks, so turn it off to silence healthcheck warnings
  rocks = {
    enabled = false,
  },
})

---------------------------------------------------------------------------
-- Treesitter bootstrap: Lua + Python
-- - installs parsers (async) if missing
-- - enables Treesitter highlight + indent for these filetypes
---------------------------------------------------------------------------

do
  -- Be defensive: don't blow up if the plugin is missing for some reason
  local ok, ts = pcall(require, "nvim-treesitter")
  if not ok then
    return
  end

  -- Optional: configure install dir (we keep defaults, so this is not needed)
  -- ts.setup({
  --   install_dir = vim.fn.stdpath("data") .. "/site",
  -- })

  -- Install parsers for Lua & Python (async, no-op if already installed)
  ts.install({ "lua", "python" })

  -- Enable Treesitter on those filetypes
  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "lua", "python" },
    callback = function(args)
      -- syntax highlighting & folds via core Neovim treesitter
      vim.treesitter.start(args.buf)

      -- Treesitter-based indentation via nvim-treesitter
      vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"

      -- If you want Treesitter folds too, uncomment:
      -- vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
      -- vim.wo.foldmethod = "expr"
    end,
  })
end

