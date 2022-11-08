require("utils")
--------------------------------------------------------------------------------

-- custom highlights
-- have to wrapped in function and regularly called due to auto-dark-mode
-- regularly resetting the theme
function customHighlights()
	local highlights = {
		"DiagnosticUnderlineError",
		"DiagnosticUnderlineWarn",
		"DiagnosticUnderlineHint",
		"DiagnosticUnderlineInfo",
		"SpellLocal",
		"SpellRare",
		"SpellCap",
		"SpellBad",
	}
	for _, v in pairs(highlights) do
		cmd("highlight " .. v .. " gui=underline")
	end

	-- active indent
	cmd [[highlight! def link IndentBlanklineContextChar Comment]]

	-- URLs
	cmd [[highlight urls cterm=underline term=underline gui=underline]]
	fn.matchadd("urls", [[http[s]\?:\/\/[[:alnum:]%\/_#.\-?:=&]*]])

	-- rainbow brackets without agressive red…
	cmd [[highlight rainbowcol1 guifg=#7e8a95]] -- no aggressively red brackets…

	-- treesittter refactor focus
	cmd [[highlight TSDefinition term=underline gui=underline]]
	cmd [[highlight TSDefinitionUsage term=underline gui=underline]]
end

customHighlights()

-- mixed whitespace
cmd [[highlight! def link MixedWhiteSpace Folded]]
cmd [[call matchadd('MixedWhiteSpace', '^\(\t\+ \| \+\t\)[ \t]*')]]

-- Annotations
cmd [[highlight! def link myAnnotations Todo]] -- use same styling as "TODO"
cmd [[call matchadd('myAnnotations', '\<\(INFO\|NOTE\|WARNING\|WARN\|REQUIRED\)\>') ]]

-- Indention
require("indent_blankline").setup {
	show_current_context = true,
	use_treesitter = true,
	strict_tabs = false,
	filetype_exclude = specialFiletypes,
	-- context_char = '┃',
}

--------------------------------------------------------------------------------
-- Notifications
opt.termguicolors = true
vim.notify = require("notify") -- use notify.nvim for all vim notifications

-- replace lua's print message with notify.nvim → https://www.reddit.com/r/neovim/comments/xv3v68/tip_nvimnotify_can_be_used_to_display_print/
print = function(...)
	local print_safe_args = {}
	local _ = {...}
	for i = 1, #_ do
		table.insert(print_safe_args, tostring(_[i]))
	end
	vim.notify(table.concat(print_safe_args, " "), "info") ---@diagnostic disable-line: param-type-mismatch
end
require("notify").setup {
	icons = { WARN = "" },
	render = "minimal", -- styles, "default"|"minimal"|"simply"
	minimum_width = 30,
	timeout = 5000,
}
--------------------------------------------------------------------------------

-- Dressing
require("dressing").setup {
	input = {
		border = borderStyle,
		winblend = 4, -- % transparency
		relative = "win",
	},
	select = {
		backend = {"builtin", "telescope", "nui"}, -- Priority list of preferred vim.select implementations
		trim_prompt = true, -- Trim trailing `:` from prompt
		builtin = {
			border = borderStyle,
			relative = "win",
			winblend = 4,
		},
		telescope = {
			initial_mode = "normal",
			prompt_prefix = "  ",
			layout_strategy = "cursor",
			results_title = "",
			sorting_strategy = "ascending",
		},
	},
}
--------------------------------------------------------------------------------
-- GUTTER
require("gitsigns").setup {
	max_file_length = 10000,
	preview_config = {border = borderStyle},
}

--------------------------------------------------------------------------------
-- DIAGNOSTICS

-- ▪︎▴• ▲  
-- https://www.reddit.com/r/neovim/comments/qpymbb/lsp_sign_in_sign_columngutter/
local signs = {
	Error = "",
	Warn = "▲",
	Info = "",
	Hint = "",
}
for type, icon in pairs(signs) do
	local hl = "DiagnosticSign" .. type
	fn.sign_define(hl, {text = icon, texthl = hl, numhl = hl}) ---@diagnostic disable-line: redundant-parameter, param-type-mismatch
end

--------------------------------------------------------------------------------
-- STATUS LINE (LuaLine)

local function alternateFile()
	local altPath = fn.expand("#:p")
	local curPath = fn.expand("%:p")
	local altFile = fn.expand("#:t")
	if altPath == curPath or altFile == "" then return "" end
	return "# " .. altFile
end

local function currentFile() -- using this function instead of default filename, since this does not show "[No Name]" for Telescope
	local curFile = fn.expand("%:t")
	if curFile == "" then return "" end
	return "%% " .. curFile -- "%" is lua's escape character and therefore needs to be escaped itself
end

local function mixedIndentation()
	if bo.filetype == "css" or bo.filetype == "markdown" or vim.tbl_contains(specialFiletypes, bo.filetype) then return "" end

	local hasTabs = fn.search("^\t", "nw") ~= 0
	local hasSpaces = fn.search("^ ", "nw") ~= 0
	local mixed = fn.search([[^\(\t\+ \| \+\t\)]], "nw") ~= 0

	if (hasSpaces and hasTabs) or mixed then
		return "  mixed"
	elseif hasSpaces and not (bo.expandtab) then
		return " et"
	elseif hasTabs and bo.expandtab then
		return " noet"
	end
	return ""
end

local secSeparators
if isGui() then
	secSeparators = {left = " ", right = " "} -- nerdfont: 'nf-ple'
else
	secSeparators = {left = "", right = ""} -- separators look off in Terminal
end

augroup("branchChange", {})
autocmd({"BufEnter", "FocusGained"}, {
	group = "branchChange",
	callback = function()
		g.cur_branch = trim(fn.system("git branch --show-current"))
	end
})

function isStandardBranch() -- not checking for branch here, since running the condition check too often results in lock files and also makes the cursor glitch for whatever reason…
	local branch = g.cur_branch
	local notMainBranch = branch ~= "main" and branch ~= "master"
	local validFiletype = bo.filetype ~= "help"
	return notMainBranch and validFiletype
end

require("lualine").setup {
	sections = {
		lualine_a = {"mode"},
		lualine_b = {{currentFile}},
		lualine_c = {{alternateFile}},
		lualine_x = {"searchcount", "diagnostics", {mixedIndentation}},
		lualine_y = {"diff", {"branch", cond = isStandardBranch}},
		lualine_z = {{"location", separator = ""}, "progress"},
	},
	options = {
		theme = "auto",
		globalstatus = true,
		component_separators = {left = "", right = ""},
		section_separators = secSeparators,
	},
}
