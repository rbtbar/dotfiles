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
    {
      "neovim/nvim-lspconfig",
      lazy = false,
      dependencies = {
        "b0o/schemastore.nvim",
      },
      config = function()
        -- Base capabilities (optionally extended by nvim-cmp if present)
        local capabilities = vim.lsp.protocol.make_client_capabilities()
        local ok_cmp, cmp_lsp = pcall(require, "cmp_nvim_lsp")
        if ok_cmp then
          capabilities = cmp_lsp.default_capabilities(capabilities)
        end

        -- JSON/YAML schemas
        local ok_schema, schemastore = pcall(require, "schemastore")

        ---------------------------------------------------------------------------
        -- Python / Lua / TS (you already had these)
        ---------------------------------------------------------------------------
        vim.lsp.config("pyright", {
          capabilities = capabilities,
        })

        vim.lsp.config("lua_ls", {
          capabilities = capabilities,
        })

        vim.lsp.config("ts_ls", {
          capabilities = capabilities,
        })

        ---------------------------------------------------------------------------
        -- JSON with schemaStore (GitHub Actions, k8s, etc.)
        ---------------------------------------------------------------------------
        vim.lsp.config("jsonls", {
          capabilities = capabilities,
          settings = ok_schema and {
            json = {
              schemas = schemastore.json.schemas(),
              validate = { enable = true },
            },
          } or nil,
        })

        ---------------------------------------------------------------------------
        -- YAML with schemaStore (k8s, GitHub Actions, docker-compose, etc.)
        ---------------------------------------------------------------------------
        vim.lsp.config("yamlls", {
          capabilities = capabilities,
          settings = ok_schema and {
            yaml = {
              -- Use schemastore instead of yamlls built-in store
              schemaStore = {
                enable = false,
                url = "",
              },
              schemas = schemastore.yaml.schemas(),
              validate = true,
              keyOrdering = false, -- don’t complain when keys aren’t sorted
            },
          } or nil,
        })

        ---------------------------------------------------------------------------
        -- Shell: bash + zsh via bashls
        ---------------------------------------------------------------------------
        vim.lsp.config("bashls", {
          capabilities = capabilities,
          filetypes = { "sh", "bash", "zsh" },
        })

        ---------------------------------------------------------------------------
        -- Docker: use the Go-based docker-language-server
        ---------------------------------------------------------------------------
        vim.lsp.config("dockerls", {
          capabilities = capabilities,
          cmd = { "docker-language-server", "start", "--stdio" },
        })



        ---------------------------------------------------------------------------
        -- Enable all of them
        ---------------------------------------------------------------------------
        vim.lsp.enable({
          "pyright",
          "lua_ls",
          "ts_ls",
          "jsonls",
          "yamlls",
          "bashls",
          "dockerls",
        })
      end,
    },

    {
      "stevearc/conform.nvim",
      event = { "BufReadPre", "BufNewFile" },
      opts = {
      formatters_by_ft = {
          -- Ruff for fixes, Black for formatting
          python = { "ruff_fix", "black" },
          ["*"] = { "trim_whitespace", "trim_newlines" },
        },
        -- no format_on_save: you trigger manually with <leader>f
      },
    },
    -- Debugging stack: core DAP + Python + UI + inline values
    {
      "mfussenegger/nvim-dap",
      dependencies = {
        "mfussenegger/nvim-dap-python",
        "rcarriga/nvim-dap-ui",
        "theHamsta/nvim-dap-virtual-text",
        "nvim-neotest/nvim-nio",
      },
      event = "VeryLazy",
      config = function()
        local dap   = require("dap")
        local dapui = require("dapui")

        ---------------------------------------------------------------------------
        -- UI setup
        ---------------------------------------------------------------------------
        dapui.setup()
        require("nvim-dap-virtual-text").setup({
          -- you can tweak, but defaults are good
        })

        -- Auto-open/close UI on session start/stop
        dap.listeners.after.event_initialized["dapui_config"] = function()
          dapui.open()
        end
        dap.listeners.before.event_terminated["dapui_config"] = function()
          dapui.close()
        end
        dap.listeners.before.event_exited["dapui_config"] = function()
          dapui.close()
        end

        ---------------------------------------------------------------------------
        -- Python (nvim-dap-python)
        ---------------------------------------------------------------------------
        local dap_python = require("dap-python")

        -- Use `python` from $PATH.
        -- If you activate a project venv before starting nvim, it will Just Work,
        -- as long as `debugpy` is installed in that env.
        dap_python.setup("python")

        ---------------------------------------------------------------------------
        -- Keymaps (global, but cheap – DAP only actually runs when you use it)
        ---------------------------------------------------------------------------
        local map = function(lhs, rhs, desc, mode)
          mode = mode or "n"
          vim.keymap.set(mode, lhs, rhs, { silent = true, desc = desc })
        end

        -- Core debug controls on <leader>d...
        map("<leader>db", dap.toggle_breakpoint, "DAP: Toggle breakpoint")
        map("<leader>dB", function()
          dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
        end, "DAP: Conditional breakpoint")

        map("<leader>dc", dap.continue,     "DAP: Continue / start")
        map("<leader>do", dap.step_over,    "DAP: Step over")
        map("<leader>di", dap.step_into,    "DAP: Step into")
        map("<leader>dO", dap.step_out,     "DAP: Step out")
        map("<leader>dr", dap.restart,      "DAP: Restart")
        map("<leader>dx", dap.terminate,    "DAP: Terminate")
        map("<leader>dr", dap.run_last,     "DAP: Run last")

        -- UI + eval
        map("<leader>du", function() dapui.toggle({}) end, "DAP: Toggle UI")
        map("<leader>de", function() dapui.eval() end,      "DAP: Eval expression")
        map("<leader>de", function() dapui.eval() end,      "DAP: Eval selection", "v")

        -- Python-specific sugar
        map("<leader>dn", function()
          dap_python.test_method()
        end, "DAP Python: debug nearest test")

        map("<leader>dN", function()
          dap_python.test_class()
        end, "DAP Python: debug test class")

        map("<leader>ds", function()
          dap_python.debug_selection()
        end, "DAP Python: debug visual selection", "v")
      end,
    },
    {
      "numToStr/Comment.nvim",
      event = { "BufReadPre", "BufNewFile" },
      config = true, -- enables default mappings: gcc, gc in visual, etc.
    },
    -- Schema Store (JSON/YAML schemas)
    {
      "b0o/schemastore.nvim",
      lazy = true,
    },
    {
      "hrsh7th/nvim-cmp",
      event = "InsertEnter",
      dependencies = {
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
      },
      config = function()
        local cmp = require("cmp")

        cmp.setup({
          snippet = {
            expand = function(_) end, -- no snippet engine yet
          },
          mapping = cmp.mapping.preset.insert({
            ["<C-Space>"] = cmp.mapping.complete(),
            ["<CR>"]      = cmp.mapping.confirm({ select = true }),
            ["<C-n>"]     = cmp.mapping.select_next_item(),
            ["<C-p>"]     = cmp.mapping.select_prev_item(),
            ["<C-e>"]     = cmp.mapping.abort(),
          }),
          sources = cmp.config.sources({
            { name = "nvim_lsp" },
            { name = "path" },
            { name = "buffer" },
          }),
        })
      end,
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

---------------------------------------------------------------------------
-- Diagnostics: visuals
---------------------------------------------------------------------------
vim.diagnostic.config({
  virtual_text  = true,
  severity_sort = true,
  float         = {
    style  = "minimal",
    border = "rounded",
    source = "if_many",
    header = "",
    prefix = "",
  },
  signs         = {
    text = {
      [vim.diagnostic.severity.ERROR] = "✘",
      [vim.diagnostic.severity.WARN]  = "▲",
      [vim.diagnostic.severity.HINT]  = "⚑",
      [vim.diagnostic.severity.INFO]  = "»",
    },
  },
})

---------------------------------------------------------------------------
-- LSP floating windows: consistent look
---------------------------------------------------------------------------
local orig_open_floating_preview = vim.lsp.util.open_floating_preview
---@diagnostic disable-next-line: duplicate-set-field
function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
  opts            = opts or {}
  opts.border     = opts.border or "rounded"
  opts.max_width  = opts.max_width or 80
  opts.max_height = opts.max_height or 24
  opts.wrap       = opts.wrap ~= false
  return orig_open_floating_preview(contents, syntax, opts, ...)
end

---------------------------------------------------------------------------
-- LSP keymaps (no format-on-save)
---------------------------------------------------------------------------
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("user.lsp", { clear = true }),
  callback = function(args)
    local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
    local buf    = args.buf

    local map = function(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = buf, silent = true, desc = desc })
    end

    -- Navigation / info
    map("n", "K",  vim.lsp.buf.hover,           "LSP hover")
    map("n", "gd", vim.lsp.buf.definition,      "LSP goto definition")
    map("n", "gD", vim.lsp.buf.declaration,     "LSP goto declaration")
    map("n", "gi", vim.lsp.buf.implementation,  "LSP goto implementation")
    map("n", "go", vim.lsp.buf.type_definition, "LSP goto type definition")
    map("n", "gr", vim.lsp.buf.references,      "LSP references")
    map("n", "gs", vim.lsp.buf.signature_help,  "LSP signature help")

    -- Diagnostics
    map("n", "gl", vim.diagnostic.open_float,   "Line diagnostics")
    map("n", "[d", vim.diagnostic.goto_prev,    "Prev diagnostic")
    map("n", "]d", vim.diagnostic.goto_next,    "Next diagnostic")

    -- Editing (manual, not on save)
    map("n", "<leader>rn", vim.lsp.buf.rename,  "LSP rename")
    map({ "n", "x" }, "<leader>f", function()
      local ok, conform = pcall(require, "conform")
      if ok then
        conform.format({
          async = true,
          lsp_fallback = true,  -- for non-Python filetypes
        })
      else
        vim.lsp.buf.format({ async = true })
      end
    end, "Format with conform/LSP")

    map("n", "<leader>ca", vim.lsp.buf.code_action, "LSP code action")
  end,
})
