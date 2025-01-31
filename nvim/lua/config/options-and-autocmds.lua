require("config/utils")
--------------------------------------------------------------------------------

-- DIRECTORIES
opt.directory:prepend(vimDataDir .. "swap//")
opt.undodir:prepend(vimDataDir .. "undo//")
opt.viewdir = vimDataDir .. "view"
opt.shadafile = vimDataDir .. "main.shada"

--------------------------------------------------------------------------------
-- Undo
opt.undofile = true -- enable persistent undo history
opt.undolevels = 500 -- less undos saved for quicker loading of undo history

local undopointChars = { "<Space>", ".", ",", ";" }
for _, char in pairs(undopointChars) do
	keymap("i", char, char .. "<C-g>u", { desc = "extra undopoint for " .. char })
end

-- timeouts
opt.timeoutlen = 1500 -- for awaiting keystrokes when there is no `nowait`
opt.updatetime = 250 -- affects current symbol highlight (treesitter-refactor) and currentline lsp-hints

-- Search
opt.showmatch = true
opt.smartcase = true
opt.ignorecase = true

-- Quickfix / Locaton List
opt.grepprg = "rg --vimgrep --no-column" -- use rg for :grep

-- Popups / Floating Windows
opt.pumheight = 15 -- max number of items in popup menu
opt.pumwidth = 10 -- min width popup menu
opt.winblend = 2 -- % transparency

-- Spelling
opt.spell = false
opt.spelllang = "en_us"

-- whitespace & indentation
opt.tabstop = 3
opt.softtabstop = 3
opt.shiftwidth = 3
opt.shiftround = true
opt.smartindent = true

-- invisible chars
opt.list = true
opt.listchars = {
	tab = "  ",
	multispace = "·",
	nbsp = "ﮊ",
	lead = "·",
	leadmultispace = "·",
	precedes = "…",
	extends = "…",
}
opt.fillchars = {
	eob = " ", -- no ~ for the eof, no dots for folds
	fold = " ", -- no dots for folds
}
opt.showbreak = "↪ " -- precedes wrapped lines

-- Split
opt.splitright = true -- vsplit right instead of left
opt.splitbelow = true -- split down instead of up

-- Window Managers/espanso: set title
opt.title = true
opt.titlelen = 0 -- do not shorten title
opt.titlestring = '%{expand("%:p")} [%{mode()}]'

-- Editor
opt.cursorline = true
opt.scrolloff = 12
opt.sidescrolloff = 18
opt.textwidth = 80
opt.wrap = false
opt.breakindent = false
opt.linebreak = true -- do not break up full words on wrap
opt.colorcolumn = "+1" -- relative to textwidth
opt.signcolumn = "yes:1" -- = gutter
opt.backspace = { "start", "eol" } -- restrict insert mode backspace behavior

-- status bar & cmdline
opt.history = 250 -- reduce noise for command history search
opt.cmdheight = 0

-- Character groups
opt.iskeyword:append("-") -- don't treat "-" as word boundary, useful e.g. for kebab-case-variables
-- opt.nrformats = "alpha" -- <C-a> and <C-x> also work on letters

--------------------------------------------------------------------------------

-- Files & Saving
opt.autochdir = true -- always current directory
opt.confirm = true -- ask instead of aborting

augroup("autosave", {})
autocmd({ "BufWinLeave", "QuitPre", "FocusLost", "InsertLeave" }, {
	group = "autosave",
	pattern = "?*", -- pattern required
	callback = function()
		local isIrregularFile = not (expand("%:p"):find("/")) -- prevent irregular files from spamming view files
		if not bo.modifiable or isIrregularFile then return end

		-- safety net to not save file in wrong folder when autochdir is not reliable
		local curFile = expand("%:p")
		cmd.update(curFile)
	end,
})

--------------------------------------------------------------------------------

-- Formatting vim.opt.formatoptions:remove("o") would not work, since it's
-- overwritten by the ftplugins having the o option. therefore needs to be set
-- via autocommand https://www.reddit.com/r/neovim/comments/sqld76/stop_automatic_newline_continuation_of_comments/
augroup("formatopts", {})
autocmd("FileType", {
	group = "formatopts",
	callback = function()
		if not (bo.filetype == "markdown") then -- not for markdown, for autolist hack (see markdown.lua)
			bo.formatoptions = bo.formatoptions:gsub("o", "")
		end
	end,
})

--------------------------------------------------------------------------------
-- FOLDING
local ufo = require("ufo")
local foldIcon = "  "
ufo.setup {
	provider_selector = function(bufnr, filetype, buftype) ---@diagnostic disable-line: unused-local
		return { "treesitter", "indent" } -- Use Treesitter as fold provider
	end,
	open_fold_hl_timeout = 0,
	fold_virt_text_handler = function(virtText, lnum, endLnum, width, truncate)
		-- https://github.com/kevinhwang91/nvim-ufo#minimal-configuration
		local newVirtText = {}
		local suffix = foldIcon .. " " .. tostring(endLnum - lnum)
		local sufWidth = vim.fn.strdisplaywidth(suffix)
		local targetWidth = width - sufWidth
		local curWidth = 0
		for _, chunk in ipairs(virtText) do
			local chunkText = chunk[1]
			local chunkWidth = vim.fn.strdisplaywidth(chunkText)
			if targetWidth > curWidth + chunkWidth then
				table.insert(newVirtText, chunk)
			else
				chunkText = truncate(chunkText, targetWidth - curWidth)
				local hlGroup = chunk[2]
				table.insert(newVirtText, { chunkText, hlGroup })
				chunkWidth = vim.fn.strdisplaywidth(chunkText)
				if curWidth + chunkWidth < targetWidth then
					suffix = suffix .. (" "):rep(targetWidth - curWidth - chunkWidth)
				end
				break
			end
			curWidth = curWidth + chunkWidth
		end
		table.insert(newVirtText, { suffix, "MoreMsg" })
		return newVirtText
	end,
}

keymap("n", "zR", ufo.openAllFolds) -- Using ufo provider need remap `zR` and `zM`
keymap("n", "zM", ufo.closeAllFolds)

-- fold settings required for UFO
opt.foldenable = true
opt.foldlevel = 99
opt.foldlevelstart = 99

-- restrict folding amount for batch-folding commands like zM
opt.foldminlines = 3
opt.foldnestmax = 1

-- if not using UFO for folding
-- opt.foldexpr = "nvim_treesitter#foldexpr()" -- if treesitter folding is used via expr below
-- opt.foldmethod = "expr"
-- opt.foldmethod = "indent"

--------------------------------------------------------------------------------

-- Remember folds and cursor
local ignoredFts = {
	"DressingSelect",
	"cybu",
	"text",
	"TelescopePrompt",
	"gitcommit",
}
augroup("rememberCursorAndFolds", {})
autocmd("BufWinLeave", {
	group = "rememberCursorAndFolds",
	pattern = "?*", -- pattern required, otherwise does not trigger
	callback = function()
		if vim.tbl_contains(ignoredFts, bo.filetype) then return end
		cmd.mkview(1)
	end,
})
autocmd("BufWinEnter", {
	group = "rememberCursorAndFolds",
	pattern = "?*",
	callback = function()
		if vim.tbl_contains(ignoredFts, bo.filetype) then return end
		cmd([[silent! loadview 1]]) -- needs silent to avoid error for documents that do not have a view yet (opening first time)
		normal("0^") -- to scroll to the left on start
	end,
})

--------------------------------------------------------------------------------

-- Skeletons (Templates)
-- apply templates for any filetype named `./templates/skeleton.{ft}`
augroup("Templates", {})
local skeletionPath = fn.stdpath("config") .. "/templates"
local filetypeList = fn.system([[ls "]] .. skeletionPath .. [[/skeleton."* | xargs basename | cut -d. -f2]])
local ftWithSkeletons = split(filetypeList, "\n")
for _, ft in pairs(ftWithSkeletons) do
	if ft == "" then break end
	local readCmd = "keepalt 0r $HOME/.config/nvim/templates/skeleton." .. ft .. " | normal! G"

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
			local curFile = expand("%")
			local fileIsEmpty = fn.getfsize(curFile) < 4 -- to account for linebreak weirdness
			if fileIsEmpty then cmd(readCmd) end
		end,
	})
end

--------------------------------------------------------------------------------

-- syntax highlighting in code blocks
g.markdown_fenced_languages = {
	"css",
	"python",
	"py=python",
	"yaml",
	"yml=yaml",
	"json",
	"lua",
	"javascript",
	"js=javascript",
	"bash",
	"sh=bash",
}
