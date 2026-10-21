# vscode-nvim

Neovim config used exclusively by the
[vscode-neovim](https://github.com/vscode-neovim/vscode-neovim) VSCode
extension (`NVIM_APPNAME=vscode-nvim`). Standalone — no LazyVim.
[lazy.nvim](https://github.com/folke/lazy.nvim) only installs plugins
(specs in `lua/plugins/`); VSCode owns all UI (statusline, highlighting,
pickers, folds).

## Plugins

| Plugin | What you get |
| --- | --- |
| leap.nvim (+ vim-repeat) | `s`/`S` jump anywhere; labeled `f`/`F`/`t`/`T` (flit successor) |
| dial.nvim | `<C-a>`/`<C-x>` on numbers, dates, booleans, `let`↔`const`, markdown `[ ]`↔`[x]`… |
| mini.ai | textobjects: `if/af` `ic/ac` `io/ao` `ia/aa` `it/at` `id` `ie` `ig` `iu/au` |
| mini.pairs | smart autopairs |
| mini.comment + nvim-ts-context-commentstring | `gc`/`gcc` with per-embedded-language commentstring |
| mini.move | `<A-h/j/k/l>` moves lines/selections |
| mini.surround | `gsa`/`gsd`/`gsr`/`gsf`/`gsF`/`gsh`/`gsn` |
| nvim-treesitter (+ textobjects) | parsers for the above + `]f`/`]c`/`]a`/`[f`… moves |

First run installs missing plugins/parsers automatically. Update with
`:Lazy sync` and `:TSUpdate`.
