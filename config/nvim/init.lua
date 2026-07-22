-----------------
-- base config --
-----------------

vim.cmd.colorscheme("catppuccin")

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

-- status line
vim.opt.statusline = " %<%f %h%m%r%=%-14.(%l,%c%V%) %P "

-- copy/paste
vim.g.clipboard = 'osc52'
vim.opt.clipboard = "unnamedplus"

-- other
vim.opt.ignorecase = true
vim.opt.scrolloff = 8
vim.opt.undofile = true
vim.opt.inccommand = "split"
vim.splitright = true
vim.splitbelow = true

vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function() vim.highlight.on_yank({ timeout = 350 }) end,
})

----------------------
-- helper functions --
----------------------

-- open a file and (optionally) put the cursor on a line
local function goto_file(file, line)
  if not file then return end
  vim.cmd.edit(vim.fn.fnameescape(file))
  if line then
    vim.api.nvim_win_set_cursor(0, { tonumber(line), 0 })
  end
end

-- run a shell pipeline in a terminal, hand the pick to `sink`
local function pick(cmd, sink)
  local tmp = vim.fn.tempname()
  vim.cmd(("botright 15split | term %s > %s"):format(cmd, tmp))
  local buf = vim.api.nvim_get_current_buf()
  vim.cmd.startinsert()
  vim.api.nvim_create_autocmd("TermClose", {
    buffer = buf,
    once = true,
    callback = function()
      vim.schedule(function()
        local ok, out = pcall(vim.fn.readfile, tmp)
        vim.fn.delete(tmp)
        if vim.api.nvim_buf_is_valid(buf) then
          vim.api.nvim_buf_delete(buf, { force = true })
        end
        if ok and out[1] and out[1] ~= "" then sink(out[1]) end
      end)
    end,
  })
end

-- Send visual selection + prompt to a tmux window
local function send_to_tmux(target)
  vim.cmd([[execute "normal! \<Esc>"]])
  local start_line = vim.fn.line("'<")
  local end_line = vim.fn.line("'>")
  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  local file_path = vim.fn.expand("%:p")

  local done = false
  vim.ui.input({ prompt = "Message: " }, function(input)
    if done or input == nil then return end
    done = true

    local payload = string.format(
      "%s\n\nFile: %s\nLines: %d:%d\n\n```\n%s\n```\n",
      input, file_path, start_line, end_line, table.concat(lines, "\n")
    )

    local load = vim.system({ "tmux", "load-buffer", "-" }, { stdin = payload }):wait()
    if load.code ~= 0 then
      vim.notify("tmux load-buffer failed", vim.log.levels.ERROR)
      return
    end
    vim.system({ "tmux", "paste-buffer", "-d", "-t", target }):wait()
  end)
end

-------------
-- keymaps --
-------------

vim.g.mapleader = " "
local keymap = vim.keymap.set
keymap("n", "<space>", "<Nop>")
keymap("n", "<leader><leader>", "<C-^>")
keymap("n", "<leader>bd", "<cmd>b#|bd#<cr>")
keymap("n", "<leader>ss", "<cmd>split<cr>")
keymap("n", "<leader>sv", "<cmd>vsplit<cr>")
keymap("n", "<leader>sc", "<cmd>close<cr>")
keymap("n", "<C-h>", "<C-w>h")
keymap("n", "<C-j>", "<C-w>j")
keymap("n", "<C-k>", "<C-w>k")
keymap("n", "<C-l>", "<C-w>l")
keymap("t", "<Esc><Esc>", "<C-\\><C-n>")


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

vim.keymap.set("x", "<leader>fi", function()
  send_to_tmux("ai")  -- window named "ai"
end, { desc = "Send selection to tmux" })

vim.keymap.set("n", "<leader>cp", function()
  local path = vim.fn.expand("%:.")
  vim.fn.setreg("+", path)
  vim.notify("Copied: " .. path)
end, { desc = "Copy relative file path" })
