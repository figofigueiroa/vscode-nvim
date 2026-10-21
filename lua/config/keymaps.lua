-- Keymaps: VSCode actions + editor tweaks.
-- Only meaningful inside the vscode-neovim extension; skip otherwise
-- (also lets `nvim --headless` boot this config for testing).
if not vim.g.vscode then
  return
end

local vscode = require("vscode")
local map = vim.keymap.set

-- VSCode navigation, ported from the old LazyVim vscode extra defaults
map("n", "<leader><space>", function()
  vscode.call("workbench.action.quickOpen")
end, { desc = "Find Files" })
map("n", "<leader>/", function()
  vscode.call("workbench.action.findInFiles")
end, { desc = "Find in Files" })
map("n", "<leader>ss", function()
  vscode.call("workbench.action.gotoSymbol")
end, { desc = "Goto Symbol" })
for _, lhs in ipairs({ "<leader>ft", "<leader>fT", "<c-/>" }) do
  map("n", lhs, function()
    vscode.call("workbench.action.terminal.toggleTerminal")
  end, { desc = "Toggle Terminal" })
end
map("n", "<S-h>", function()
  vscode.call("workbench.action.previousEditor")
end, { desc = "Previous Editor" })
map("n", "<S-l>", function()
  vscode.call("workbench.action.nextEditor")
end, { desc = "Next Editor" })

map({ "n", "x" }, "<leader>e", function()
  vscode.action("workbench.view.explorer")
end)

map({ "n", "x" }, "<leader>cr", function()
  vscode.action("editor.action.rename")
end)

map({ "n", "x" }, "<leader>ca", function()
  vscode.action("editor.action.codeAction")
end)

map({ "n", "x" }, "<leader>cc", function()
  vscode.action("codelens.showLensesInCurrentLine")
end)

map("n", "gai", function()
  vscode.call("editor.showCallHierarchy")
end)

map("n", "gao", function()
  vscode.call("editor.showOutgoingCalls")
end)

map("n", "<leader>uz", function()
  vscode.action("workbench.action.toggleZenMode")
end)
map("n", "gr", function()
  vscode.action("editor.action.goToReferences")
end)
map("n", "za", ':call VSCodeNotify("editor.toggleFold")<cr>', { desc = "toggle fold" })
map("n", "zc", ':call VSCodeNotify("editor.fold")<cr>', { desc = "toggle fold" })
map("n", "zo", ':call VSCodeNotify("editor.unfold")<cr>', { desc = "toggle fold" })
map("n", "zM", ':call VSCodeNotify("editor.foldAll")<cr>', { desc = "fold all" })
map("n", "zR", ':call VSCodeNotify("editor.unfoldAll")<cr>', { desc = "unfold all" })

map("n", "<leader>fc", function()
  vscode.action("workbench.action.openSettingsJson")
end, { desc = "Open config file" })

map("n", "<leader>gi", function()
  vscode.action("issues:github.focus")
end, { desc = "Open repo issues" })

map("n", "<leader>m", function()
  vscode.action("bookmarks.toggle")
end, { desc = "toggle bookmark" })

map("n", "<leader>mn", function()
  vscode.action("bookmarks.jumpToNext")
end, { desc = "Jump to next bookmark" })

map("n", "<leader>mp", function()
  vscode.action("bookmarks.jumpToPrevious")
end, { desc = "Jump to previous bookmark" })

map("n", "<leader>sm", function()
  vscode.action("bookmarks.list")
end, { desc = "search file bookmarks" })

map("n", "<leader>sM", function()
  vscode.action("bookmarks.listFromAllFiles")
end, { desc = "search workspace bookmarks" })

map("n", "<leader>db", function()
  vscode.action("editor.debug.action.toggleBreakpoint")
end, { desc = "toggle breakpoint" })

-- Better up and down
-- Fix folds were automatically opening when navigating with j, k
map("n", "j", function()
  if vim.v.count == 0 then
    vscode.call("cursorDown")
  else
    return "j"
  end
end, { expr = true })

map("n", "k", function()
  if vim.v.count == 0 then
    vscode.call("cursorUp")
  else
    return "k"
  end
end, { expr = true })

-- incremental selection via VSCode smart select. Delivery: the ctrl+space
-- keybinding in keybindings.json sends "<C-space>" here (vscode-neovim.send
-- → nvim_input); repeat presses land in visual mode, hence the "x" mode.
-- This replaces the old flash.nvim =z treesitter-select.
map({ "n", "x" }, "<C-Space>", function()
  vscode.action("editor.action.smartSelect.expand")
end, { desc = "Treesitter Incremental Selection" })

-- shrink lives primarily in keybindings.json (backspace + editorHasSelection
-- → smartSelect.shrink) because after ctrl+space nvim can still be in normal
-- mode; this x-mode map is the fallback when the key actually reaches nvim.
map("x", "<BS>", function()
  vscode.action("editor.action.smartSelect.shrink")
end, { desc = "Treesitter Decremental Selection" })

map({ "n", "x" }, "<leader>r", function()
  vscode.action("editor.action.refactor")
end, { desc = "Refactor" })

map({ "n", "x" }, "<leader><tab>l", function()
  vscode.action("workbench.action.quickOpenPreviousRecentlyUsedEditorInGroup")
end, { desc = "Recent Editor" })

map({ "n", "x" }, "d", '"_d', { desc = "Black hole delete" })
map({ "n", "x" }, "c", '"_c', { desc = "Black hole change" })
map("n", "D", '"_D', { desc = "Black hole delete line" })
map("n", "C", '"_C', { desc = "Black hole change line" })
