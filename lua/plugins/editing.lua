-- Editing plugins, ported from LazyVim specs without the distro.
-- Everything loads at startup (lazy = false); only dial defers to its keys.

-- labeled f/F/t/T motions (flit.nvim is discontinued; its feature lives in
-- leap now — this is the official leap FAQ snippet)
local function leap_ft(kwargs)
  require("leap").leap(vim.tbl_deep_extend("keep", kwargs, {
    inputlen = 1,
    inclusive = true,
    opts = {
      labels = "", -- force autojump
      safe_labels = vim.fn.mode(1):match("no?") and "" or nil,
    },
  }))
end

-- whole-buffer textobject (ii/ai), from LazyVim (MiniExtra.gen_ai_spec.buffer)
local function ai_buffer(ai_type)
  local start_line, end_line = 1, vim.fn.line("$")
  if ai_type == "i" then
    -- Skip first and last blank lines for `i`
    local first_nonblank, last_nonblank = vim.fn.nextnonblank(start_line), vim.fn.prevnonblank(end_line)
    if first_nonblank == 0 or last_nonblank == 0 then
      return { from = { line = start_line, col = 1 } }
    end
    start_line, end_line = first_nonblank, last_nonblank
  end
  local to_col = math.max(vim.fn.getline(end_line):len(), 1)
  return { from = { line = start_line, col = 1 }, to = { line = end_line, col = to_col } }
end

-- dial helper (LazyVim): pick the augend group for the current filetype
local function dial(increment, g)
  local mode = vim.fn.mode(true)
  -- Use visual commands for VISUAL 'v', VISUAL LINE 'V' and VISUAL BLOCK '\22'
  local is_visual = mode == "v" or mode == "V" or mode == "\22"
  local func = (increment and "inc" or "dec") .. (g and "_g" or "_") .. (is_visual and "visual" or "normal")
  local group = vim.g.dials_by_ft[vim.bo.filetype] or "default"
  return require("dial.map")[func](group)
end

-- treesitter textobject with on-demand parse: with highlighting off (VSCode
-- owns it) nothing parses the buffer, so parse here or mini.ai finds no nodes.
-- Incremental after the first call, so cheap at point of use.
local function ts_parse_current()
  local ok, parser = pcall(vim.treesitter.get_parser, 0)
  if ok then
    parser:parse(true)
  end
end

local function ts_spec(captures)
  local spec = require("mini.ai").gen_spec.treesitter(captures)
  return function(ai_type, id, opts)
    ts_parse_current()
    return spec(ai_type, id, opts)
  end
end

return {

  -- leap: jump to any visible target with s/S (2-char search + labels)
  {
    "https://codeberg.org/andyg/leap.nvim.git",
    dependencies = { "tpope/vim-repeat" },
    config = function()
      local leap = require("leap")
      leap.add_default_mappings(true)
      vim.keymap.del({ "x", "o" }, "x") -- keep visual x/X as cut
      vim.keymap.del({ "x", "o" }, "X")
      -- shortcut: leap-from-window (gs) sacrificed so mini.surround keeps the
      -- gs prefix from the old setup; remap it (e.g. gz) if you miss it
      vim.keymap.del({ "n", "x", "o" }, "gs")

      local clever = require("leap.user").with_traversal_keys
      local clever_f, clever_t = clever("f", "F"), clever("t", "T")
      vim.keymap.set({ "n", "x", "o" }, "f", function()
        leap_ft({ opts = clever_f })
      end)
      vim.keymap.set({ "n", "x", "o" }, "F", function()
        leap_ft({ backward = true, opts = clever_f })
      end)
      vim.keymap.set({ "n", "x", "o" }, "t", function()
        leap_ft({ offset = -1, opts = clever_t })
      end)
      vim.keymap.set({ "n", "x", "o" }, "T", function()
        leap_ft({ backward = true, offset = 1, opts = clever_t })
      end)
    end,
  },

  -- enhanced <C-a>/<C-x>: numbers, dates, booleans, let<->const,
  -- markdown checkboxes, hex colors... (LazyVim dial extra, verbatim)
  {
    "monaqa/dial.nvim",
    -- stylua: ignore
    keys = {
      { "<C-a>", function() return dial(true) end, expr = true, desc = "Increment", mode = { "n", "v" } },
      { "<C-x>", function() return dial(false) end, expr = true, desc = "Decrement", mode = { "n", "v" } },
      { "g<C-a>", function() return dial(true, true) end, expr = true, desc = "Increment", mode = { "n", "x" } },
      { "g<C-x>", function() return dial(false, true) end, expr = true, desc = "Decrement", mode = { "n", "x" } },
    },
    opts = function()
      local augend = require("dial.augend")

      local logical_alias = augend.constant.new({
        elements = { "&&", "||" },
        word = false,
        cyclic = true,
      })

      local ordinal_numbers = augend.constant.new({
        elements = { "first", "second", "third", "fourth", "fifth", "sixth", "seventh", "eighth", "ninth", "tenth" },
        word = false,
        cyclic = true,
      })

      local months = augend.constant.new({
        elements = {
          "January", "February", "March", "April", "May", "June",
          "July", "August", "September", "October", "November", "December",
        },
        word = true,
        cyclic = true,
      })

      return {
        dials_by_ft = {
          css = "css",
          vue = "vue",
          javascript = "typescript",
          typescript = "typescript",
          typescriptreact = "typescript",
          javascriptreact = "typescript",
          json = "json",
          lua = "lua",
          markdown = "markdown",
          sass = "css",
          scss = "css",
          python = "python",
        },
        groups = {
          default = {
            augend.integer.alias.decimal,
            augend.integer.alias.decimal_int,
            augend.integer.alias.hex,
            augend.date.alias["%Y/%m/%d"],
            augend.constant.alias.en_weekday,
            augend.constant.alias.en_weekday_full,
            ordinal_numbers,
            months,
            augend.constant.alias.bool,
            augend.constant.alias.Bool,
            logical_alias,
          },
          typescript = {
            augend.constant.new({ elements = { "let", "const" }, word = true, cyclic = true }),
          },
          css = {
            augend.hexcolor.new({ case = "lower" }),
            augend.hexcolor.new({ case = "upper" }),
          },
          markdown = {
            augend.constant.new({ elements = { "[ ]", "[x]" }, word = false, cyclic = true }),
            augend.misc.alias.markdown_header,
          },
          json = {
            augend.semver.alias.semver,
          },
          lua = {
            augend.constant.new({ elements = { "and", "or" }, word = true, cyclic = true }),
          },
          python = {
            augend.constant.new({ elements = { "and", "or" }, word = true, cyclic = true }),
          },
        },
      }
    end,
    config = function(_, opts)
      -- copy defaults to each group
      for name, group in pairs(opts.groups) do
        if name ~= "default" then
          vim.list_extend(group, opts.groups.default)
        end
      end
      require("dial.config").augends:register_group(opts.groups)
      vim.g.dials_by_ft = opts.dials_by_ft
    end,
  },

  -- extended textobjects: if/af function, ic/ac class, io/ao block, ia/aa
  -- argument, it/at tag, id digits, ie word-with-case, ig buffer, iu/au call
  {
    "nvim-mini/mini.ai",
    config = function()
      local ai = require("mini.ai")
      ai.setup({
        n_lines = 500,
        custom_textobjects = {
          o = ts_spec({ -- code block
            a = { "@block.outer", "@conditional.outer", "@loop.outer" },
            i = { "@block.inner", "@conditional.inner", "@loop.inner" },
          }),
          f = ts_spec({ a = "@function.outer", i = "@function.inner" }), -- function
          c = ts_spec({ a = "@class.outer", i = "@class.inner" }), -- class
          t = { "<([%p%w]-)%f[^<%w][^<>]->.-</%1>", "^<.->().*()</[^/]->$" }, -- tags
          d = { "%f[%d]%d+" }, -- digits
          e = { -- word with case (camelCase / snake_case)
            { "%u[%l%d]+%f[^%l%d]", "%f[%S][%l%d]+%f[^%l%d]", "%f[%P][%l%d]+%f[^%l%d]", "^[%l%d]+%f[^%l%d]" },
            "^().*()$",
          },
          g = ai_buffer, -- whole buffer
          u = ai.gen_spec.function_call(), -- "usage": function call
          U = ai.gen_spec.function_call({ name_pattern = "[%w_]" }), -- without dot in name
        },
      })
    end,
  },

  -- autopairs (LazyVim's behavior: skip when next char is word/quote,
  -- skip unbalanced closers, triple-backtick for markdown code blocks)
  {
    "nvim-mini/mini.pairs",
    config = function()
      local opts = {
        modes = { insert = true, command = true, terminal = false },
        skip_next = [=[[%w%%%'%[%"%.%`%$]]=],
        skip_unbalanced = true,
        markdown = true,
      }
      local pairs = require("mini.pairs")
      pairs.setup(opts)
      local open = pairs.open
      pairs.open = function(pair, neigh_pattern)
        if vim.fn.getcmdline() ~= "" then
          return open(pair, neigh_pattern)
        end
        local o, c = pair:sub(1, 1), pair:sub(2, 2)
        local line = vim.api.nvim_get_current_line()
        local cursor = vim.api.nvim_win_get_cursor(0)
        local next = line:sub(cursor[2] + 1, cursor[2] + 1)
        local before = line:sub(1, cursor[2])
        if opts.markdown and o == "`" and vim.bo.filetype == "markdown" and before:match("^%s*``") then
          return "`\n```" .. vim.api.nvim_replace_termcodes("<up>", true, true, true)
        end
        if opts.skip_next and next ~= "" and next:match(opts.skip_next) then
          return o
        end
        if opts.skip_unbalanced and next == c and c ~= o then
          local _, count_open = line:gsub(vim.pesc(pair:sub(1, 1)), "")
          local _, count_close = line:gsub(vim.pesc(pair:sub(2, 2)), "")
          if count_close > count_open then
            return o
          end
        end
        return open(pair, neigh_pattern)
      end
    end,
  },

  -- commenting, with per-embedded-language commentstrings (tsx, vue, html...)
  {
    "nvim-mini/mini.comment",
    dependencies = { "JoosepAlviste/nvim-ts-context-commentstring" },
    config = function()
      require("mini.comment").setup({
        options = {
          custom_commentstring = function()
            -- parse on demand (no highlight = no parse in vscode-neovim);
            -- needed for embedded languages (tsx/vue/html)
            ts_parse_current()
            return require("ts_context_commentstring.internal").calculate_commentstring()
              or vim.bo.commentstring
          end,
        },
      })
    end,
  },
  {
    "JoosepAlviste/nvim-ts-context-commentstring",
    config = function()
      -- calculated on demand by mini.comment above, no idle autocmd needed
      require("ts_context_commentstring").setup({ enable_autocmd = false })
    end,
  },

  -- move lines/selections with <A-h>/<A-j>/<A-k>/<A-l>
  { "nvim-mini/mini.move", opts = {} },

  -- surround on the gs prefix, as in the old setup:
  -- gsa add, gsd delete, gsr replace, gsf/gsF find, gsh highlight, gsn n_lines
  {
    "nvim-mini/mini.surround",
    opts = {
      mappings = {
        add = "gsa",
        delete = "gsd",
        find = "gsf",
        find_left = "gsF",
        highlight = "gsh",
        replace = "gsr",
        update_n_lines = "gsn",
      },
    },
  },
}
