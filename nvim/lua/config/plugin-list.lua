-- alternative setup method https://www.reddit.com/r/neovim/comments/zk187u/how_does_everyone_segment_plugin_development_from/
local myrepos = vim.fn.stdpath("config") .. "/my-plugins/"

--------------------------------------------------------------------------------
-- stylua: ignore start
return {

	-- Package Management
	"wbthomason/packer.nvim", -- packer manages itself
	"lewis6991/impatient.nvim", -- reduces startup time by ~50%
	{"williamboman/mason.nvim", requires = "RubixDev/mason-update-all"},

	-- Themes
	"savq/melange", -- like Obsidian's Primary color scheme
	"nyoom-engineering/oxocarbon.nvim",
	-- "folke/tokyonight.nvim",
	-- "EdenEast/nightfox.nvim",
	-- "rebelot/kanagawa.nvim",

	-- Treesitter
	{"nvim-treesitter/nvim-treesitter",
		run = function() -- auto-update parsers on start: https://github.com/nvim-treesitter/nvim-treesitter/wiki/Installation#packernvim
			require("nvim-treesitter.install").update {with_sync = true}
		end,
		requires = {
			"nvim-treesitter/nvim-treesitter-refactor",
			"nvim-treesitter/nvim-treesitter-textobjects",
			"p00f/nvim-ts-rainbow", -- colored brackets
	}},

	{"mizlan/iswap.nvim", -- swapping of notes
		config = function() require("iswap").setup {autoswap = true} end,
		cmd = "ISwapWith"
	},
	{"m-demare/hlargs.nvim", -- highlight function args
		config = function() require("hlargs").setup() end,
	},
	{"Wansmer/treesj", -- split-join
		requires = {
			"nvim-treesitter/nvim-treesitter",
			"AndrewRadev/splitjoin.vim", -- only used as fallback. TODO: remove when treesj has wider language support
	}},
	{"cshuaimin/ssr.nvim", -- structural search & replace
		module = "ssr",
		commit = "4304933", -- TODO: update to newest version with nvim 0.9 https://github.com/cshuaimin/ssr.nvim/issues/11#issuecomment-1340671193
		config = function()
			require("ssr").setup {
				keymaps = {close = "Q"},
			}
		end
	},

	-- LSP
	{"neovim/nvim-lspconfig", requires = {
		"williamboman/mason-lspconfig.nvim",
		"lvimuser/lsp-inlayhints.nvim", -- only temporarily needed, until https://github.com/neovim/neovim/issues/18086
		"ray-x/lsp_signature.nvim", -- signature hint
		"SmiteshP/nvim-navic", -- breadcrumbs
		"folke/neodev.nvim", -- lsp for nvim-lua config
		"b0o/SchemaStore.nvim", -- schemas for json-lsp
	}},

	-- Linting & Formatting
	{"jose-elias-alvarez/null-ls.nvim", requires = {
		"nvim-lua/plenary.nvim",
		"jayp0521/mason-null-ls.nvim",
	}},

	-- DAP
	{"mfussenegger/nvim-dap", requires = {
		"jayp0521/mason-nvim-dap.nvim",
		"theHamsta/nvim-dap-virtual-text",
		"rcarriga/nvim-dap-ui",
		"jbyuki/one-small-step-for-vimkind", -- lua debugger specifically for neovim config
	}},

	-- Completion & Suggestion
	{"hrsh7th/nvim-cmp", requires = {
		"hrsh7th/cmp-buffer", -- completion sources
		"hrsh7th/cmp-path",
		"hrsh7th/cmp-cmdline",
		"dmitmel/cmp-cmdline-history",
		"hrsh7th/cmp-emoji",
		myrepos .. "cmp-nerdfont",
		"tamago324/cmp-zsh",
		"ray-x/cmp-treesitter",
		"hrsh7th/cmp-nvim-lsp", -- lsp
		"L3MON4D3/LuaSnip", -- snippet engine
		"saadparwaiz1/cmp_luasnip", -- adapter for snippet engine
	}},
	{"windwp/nvim-autopairs", requires = "hrsh7th/nvim-cmp"},

	-- AI-Support
	{"tzachar/cmp-tabnine", run = "./install.sh", requires = "hrsh7th/nvim-cmp"},
	{"jackMort/ChatGPT.nvim", requires = {
		"MunifTanjim/nui.nvim",
		"nvim-lua/plenary.nvim",
	}},

	-- Appearance
	"lukas-reineke/indent-blankline.nvim", -- indentation guides
	"nvim-lualine/lualine.nvim", -- status line
	"lewis6991/gitsigns.nvim", -- gutter signs
	"rcarriga/nvim-notify", -- notifications
	"uga-rosa/ccc.nvim", -- color previews & color utilities
	"dstein64/nvim-scrollview", -- "petertriho/nvim-scrollbar" has more features, but is also more buggy atm
	{"anuvyklack/windows.nvim", requires = "anuvyklack/middleclass"}, -- auto-resize splits
	"xiyaowong/virtcolumn.nvim",

	-- File Switching & File Operation
	{"stevearc/dressing.nvim", requires = {
		"hrsh7th/nvim-cmp",
		"hrsh7th/cmp-omni", -- for autocompletion in input prompts
	}},
	{myrepos .. "nvim-genghis",
		module = "genghis",
		requires = "stevearc/dressing.nvim",
	},
	{"nvim-telescope/telescope.nvim", requires = {
		"nvim-lua/plenary.nvim",
		"kyazdani42/nvim-web-devicons"
	}},
	{"ghillb/cybu.nvim", requires = {-- Cycle Buffers
		"nvim-tree/nvim-web-devicons",
		"nvim-lua/plenary.nvim",
	}},
	{ "debugloop/telescope-undo.nvim",
		requires = {"nvim-telescope/telescope.nvim"},
		config = function() require("telescope").load_extension("undo") end,
		module = "telescope-undo",
	},

	-- Terminal & Git
	{"akinsho/toggleterm.nvim",
		cmd = {"ToggleTerm", "ToggleTermSendVisualSelection"},
		config = function() require("toggleterm").setup() end
	},
	{"sindrets/diffview.nvim",
		requires = "nvim-lua/plenary.nvim",
		cmd = {"DiffviewFileHistory", "DiffviewOpen"},
		config = function()
			require("diffview").setup {
				file_history_panel = {win_config = {height = 4}},
			}
		end,
	},
	{"ruifm/gitlinker.nvim",
		requires = "nvim-lua/plenary.nvim",
		module = "gitlinker",
		config = function()
			require("gitlinker").setup {
				mappings = nil,
				opts = {print_url = false},
			}
		end
	},

	-- EDITING-SUPPORT
	"kylechui/nvim-surround", -- surround operator
	"gbprod/substitute.nvim", -- substitution & exchange operator
	"numToStr/Comment.nvim", -- comment operator
	{"mg979/vim-visual-multi", keys = {{"n", "<D-j>"}, {"x", "<D-j>"}}},
	"Darazaki/indent-o-matic", -- auto-determine indents
	{"gbprod/yanky.nvim"}, -- register manager
	myrepos .. "nvim-recorder", -- better macros
	myrepos .. "nvim-various-textobjs", -- custom textobjects
	{"nacro90/numb.nvim", -- line previews when ":n"
		config = function() require("numb").setup() end,
		keys = {{"n", ":"}},
	},
	{"kevinhwang91/nvim-ufo", requires = "kevinhwang91/promise-async"}, -- better folding
	"unblevable/quick-scope", -- f/t preview

	-- Filetype-specific
	{"mityu/vim-applescript", ft = "applescript"}, -- syntax highlighting
	{"hail2u/vim-css3-syntax", ft = "css"}, -- better syntax highlighting (until treesitter css looks decent…)
	{"iamcco/markdown-preview.nvim", ft = "markdown", run = "cd app && npm install"},
	{"bennypowers/nvim-regexplainer",
		ft = {"javascript", "typescript"},
		requires = {"nvim-treesitter/nvim-treesitter", "MunifTanjim/nui.nvim"},
		-- INFO: config set in javascript/typescript ftplugin, since not working
		-- from here
	},

}
