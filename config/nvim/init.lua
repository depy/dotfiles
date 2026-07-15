-----------------
-- base config --
-----------------

-- line numbers
vim.opt.number = true
vim.opt.relativenumber = true

-- styling (remove background, color status line, ...)
vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
vim.api.nvim_set_hl(0, "StatusLine", { fg = "#cdd6f4", bg = "#1e1e2e" })

-- indentation
vim.opt.autoindent = true
vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4

vim.opt.ignorecase = true
vim.opt.scrolloff = 8
vim.opt.undofile = true

-- status line
vim.opt.statusline = " %<%f %h%m%r%=%-14.(%l,%c%V%) %P "

----------------------
-- helper functions --
----------------------

-- open a file and (optionally) put the cursor on a line
local function goto_file(file, line)
  if not file then return end
  vim.cmd.edit(file)
  if line then
    vim.api.nvim_win_set_cursor(0, { tonumber(line), 0 })
  end
end

-- run a shell pipeline in a terminal, hand the pick to `sink`
local function pick(cmd, sink)
  local tmp = vim.fn.tempname()
  vim.cmd(("botright 15split | term %s > %s"):format(cmd, tmp))
  vim.cmd.startinsert()
  vim.api.nvim_create_autocmd("TermClose", {
    once = true,
    callback = function()
      local ok, out = pcall(vim.fn.readfile, tmp)
      vim.cmd.bwipeout({ bang = true })
      if ok and out[1] and out[1] ~= "" then sink(out[1]) end
    end,
  })
end

-------------
-- keymaps --
-------------

vim.g.mapleader = " "
local keymap = vim.keymap.set
keymap("n", "<space>", "<Nop>")
keymap("n", "<leader><leader>", "<C-^>")

keymap("n", "<leader>ff", function()
  pick("fzf", goto_file)
end)

keymap("n", "<leader>fg", function()
  local rg = "rg --color=always --line-number --smart-case"
  local cmd = ('fzf --ansi --disabled --bind "start,change:reload:%s {q} || true"'):format(rg)
  pick(cmd, function(line)
    goto_file(line:match("^(.-):(%d+):"))
  end)
end)

keymap("n", "<leader>fG", function()
  local rg = "rg --color=always --line-number --smart-case ''"
  local cmd = ("%s | fzf --ansi --delimiter : --nth 3.."):format(rg)
  pick(cmd, function(line)
    goto_file(line:match("^(.-):(%d+):"))
  end)
end)

keymap("n", "<leader>bb", function()
  local lines = {}
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[b].buflisted
      and vim.api.nvim_buf_is_loaded(b)
      and vim.bo[b].buftype == ""
      and vim.api.nvim_buf_get_name(b) ~= ""
    then
      table.insert(lines, b .. "\t" .. vim.api.nvim_buf_get_name(b))
    end
  end
  local list = vim.fn.tempname()
  vim.fn.writefile(lines, list)
  pick(("cat %s | fzf"):format(list), function(sel)
    vim.cmd.buffer(sel:match("^(%d+)"))
  end)
end)
