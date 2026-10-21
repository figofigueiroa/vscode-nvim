-- Treesitter: parser installation + textobject queries/moves only.
-- Highlighting/indent/folds stay OFF — VSCode owns those, and skipping them
-- keeps the vscode-neovim bridge light (no highlight/extmark traffic).
return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main", -- rewrite branch, requires Neovim >= 0.12
    build = ":TSUpdate",
    opts = {
      ensure_installed = {
        "bash",
        "c_sharp",
        "go",
        "html",
        "javascript",
        "json",
        "lua",
        "markdown",
        "markdown_inline",
        "python",
        "query",
        "regex",
        "tsx",
        "typescript",
        "vim",
        "yaml",
      },
    },
    config = function(_, opts)
      -- async, no-op for parsers already installed; default install_dir is fine
      require("nvim-treesitter").install(opts.ensure_installed)
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    config = function()
      require("nvim-treesitter-textobjects").setup({
        move = { set_jumps = true },
      })
      local move = require("nvim-treesitter-textobjects.move")
      -- shortcut: global maps with pcall (no-op on buffers without a parser),
      -- ]c/[c override vim's diff-only maps — irrelevant inside VSCode
      local maps = {
        { "]f", "goto_next_start", "@function.outer", "Next function start" },
        { "]c", "goto_next_start", "@class.outer", "Next class start" },
        { "]a", "goto_next_start", "@parameter.inner", "Next argument start" },
        { "]F", "goto_next_end", "@function.outer", "Next function end" },
        { "]C", "goto_next_end", "@class.outer", "Next class end" },
        { "]A", "goto_next_end", "@parameter.inner", "Next argument end" },
        { "[f", "goto_previous_start", "@function.outer", "Previous function start" },
        { "[c", "goto_previous_start", "@class.outer", "Previous class start" },
        { "[a", "goto_previous_start", "@parameter.inner", "Previous argument start" },
        { "[F", "goto_previous_end", "@function.outer", "Previous function end" },
        { "[C", "goto_previous_end", "@class.outer", "Previous class end" },
        { "[A", "goto_previous_end", "@parameter.inner", "Previous argument end" },
      }
      for _, m in ipairs(maps) do
        vim.keymap.set({ "n", "x", "o" }, m[1], function()
          pcall(move[m[2]], m[3], "textobjects")
        end, { silent = true, desc = m[4] })
      end
    end,
  },
}
