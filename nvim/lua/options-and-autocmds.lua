require("utils")
--------------------------------------------------------------------------------

-- timeout for awaiting keystrokes
opt.timeoutlen = 2000 -- yes, I'm slow lol

-- Search
opt.showmatch = true
opt.smartcase = true
opt.ignorecase = true

-- Popup
opt.pumheight = 15 -- max number of items in popup menu
opt.pumwidth = 10 -- min width popup menu

-- Spelling
opt.spell = false
opt.spelllang = "en_us"

-- Gutter
opt.fillchars = "eob: " -- hide the ugly "~" marking the end of the buffer
opt.numberwidth = 3 -- minimum width, save some space for shorter files
opt.number = false
opt.relativenumber = false

-- whitespace & indentation
opt.tabstop = 3
opt.softtabstop = 3
opt.shiftwidth = 3
opt.shiftround = true
opt.smartindent = true
opt.list = true
opt.listchars = "multispace:··,tab:  ,nbsp:ﮊ"
opt.virtualedit = "block" -- select whitespace for proper rectangles in visual block mode

-- Split
opt.splitright = true -- vsplit right instead of left
opt.splitbelow = true -- split down instead of up

-- Window Managers/espanso: set title
opt.title = true
opt.titlelen = 0 -- do not shorten title
opt.titlestring = "%{expand(\"%:p\")} [%{mode()}]"

-- Editor
opt.cursorline = true
opt.scrolloff = 12
opt.sidescrolloff = 20
opt.textwidth = 80 -- used by `gq`
opt.wrap = false
opt.colorcolumn = {"+1", "+18"} -- relative to textwidth
opt.signcolumn = "yes:1" -- = gutter

-- Formatting vim.opt.formatoptions:remove("o") would not work, since it's
-- overwritten by the ftplugins having the o option. therefore needs to be set
-- via autocommand https://www.reddit.com/r/neovim/comments/sqld76/stop_automatic_newline_continuation_of_comments/
augroup("formatopts", {})
autocmd("BufEnter", {
	group = "formatopts",
	callback = function()
		if not (bo.filetype == "markdown") then -- not for markdown, for autolist hack (see markdown.lua)
			bo.formatoptions = bo.formatoptions:gsub("[ro]", "")
		end
	end
})

-- Remember Cursor Position
augroup("rememberCursorPosition", {})
autocmd("BufReadPost", {
	group = "rememberCursorPosition",
	callback = function()
		local jumpcmd
		if bo.filetype == "commit" then
			return
		elseif bo.filetype == "log" or bo.filetype == "" then -- for log files jump to the bottom
			jumpcmd = "G"
		elseif fn.line [['"]] >= fn.line [[$]] then -- in case file has been shortened outside of vim
			jumpcmd = "G"
		elseif fn.line [['"]] >= 1 then -- check file has been entered already
			jumpcmd = [['"]]
		end
		cmd("keepjumps normal! " .. jumpcmd)
	end,
})

-- clipboard & yanking
opt.clipboard = "unnamedplus"
augroup("highlightedYank", {})
autocmd("TextYankPost", {
	group = "highlightedYank",
	callback = function() vim.highlight.on_yank {timeout = 2000} end
})

-- don't treat "-" as word boundary
opt.iskeyword:append("-")

--------------------------------------------------------------------------------

-- FILES & SAVING
opt.hidden = true -- inactive buffers are only hidden, not unloaded
opt.undofile = true -- persistent undo history
opt.updatetime = 200 -- affects current symbol highlight (treesitter-refactor) and currentline lsp-hints
opt.autochdir = true -- always current directory
opt.confirm = true

augroup("autosave", {})
autocmd({"BufWinLeave", "BufLeave", "QuitPre", "FocusLost", "InsertLeave"}, {
	group = "autosave",
	pattern = "?*",
	command = "silent! update"
})

augroup("Mini-Lint", {}) -- trim trailing whitespaces & extra blanks at eof on save
autocmd("BufWritePre", {
	group = "Mini-Lint",
	callback = function()
		local save_view = fn.winsaveview() -- save cursor positon
		if bo.filetype ~= "markdown" then -- to preserve spaces from the two-space-rule, and trailing spaces on sentences
			cmd [[%s/\s\+$//e]]
		end
		cmd [[silent! %s#\($\n\s*\)\+\%$##]] -- https://stackoverflow.com/a/7496112
		fn.winrestview(save_view)
	end
})

--------------------------------------------------------------------------------

-- status bar & cmdline
-- opt.showcmd = true -- keychords pressed
-- opt.showmode = false -- don't show "-- Insert --", since lualine does it already
-- opt.shortmess:append("S") -- do not show search count, since lualine does it already
-- opt.laststatus = 3 -- = global status line
opt.cmdheight = 0 -- effectively also redundant with all of the above
opt.history = 250 -- do not save too much history to reduce noise for command line history search

--------------------------------------------------------------------------------

-- folding
opt.foldmethod = "indent"
opt.foldenable = false -- do not fold on start
augroup("rememberFolds", {}) -- keep folds on save https://stackoverflow.com/questions/37552913/vim-how-to-keep-folds-on-save
autocmd("BufWinLeave", {
	group = "rememberFolds",
	pattern = "?*",
	command = "silent! mkview"
})
autocmd("BufWinEnter", {
	group = "rememberFolds",
	pattern = "?*",
	command = "silent! loadview"
})

--------------------------------------------------------------------------------

-- Terminal Mode
augroup("Terminal", {})
autocmd("TermOpen", {
	group = "Terminal",
	pattern = "*",
	command = "startinsert",
})
autocmd("TermClose", {
	group = "Terminal",
	pattern = "*",
	command = "bd",
})

--------------------------------------------------------------------------------

-- Skeletons (Templates)
-- apply templates for any filetype named `.config/nvim/templates/skeletion.{ft}`
augroup("Templates", {})
local filetypeList = fn.system('ls "$HOME/.config/nvim/templates/skeleton."* | xargs basename | cut -d. -f2')
local ftWithSkeletons = split(filetypeList, "\n")
for _, ft in pairs(ftWithSkeletons) do
	if ft == "" then break end
	local readCmd = "0r $HOME/.config/nvim/templates/skeleton." .. ft .. " | normal! Go"

	autocmd("BufNewFile", {
		group = "Templates",
		pattern = "*." .. ft,
		command = readCmd,
	})

	-- BufReadPost + empty file as additional condition to also auto-insert
	-- skeletons when empty files were created by other apps
	autocmd("BufReadPost", {
		group = "Templates",
		pattern = "*." .. ft,
		callback = function()
			local curFile = fn.expand("%")
			local fileIsEmpty = fn.getfsize(curFile) < 2 -- 2 to account for linebreak
			if fileIsEmpty then cmd(readCmd) end
		end
	})
end
