vim.opt.runtimepath:append(', "~/.config/nvim/lua"') -- apparently required for homebrew installs where the runtimepath is missing the .config directory?!

require("packer-setup") -- must be 1st
require("utils") -- must be 2nd

require("options")
require("keybindings")
require("filetype-specific")
require("remaining-plugins")

if (g.neovide or g.goneovim) then
	require("gui-settings")
	require("color-utilities")
end

require("telescope-config")
require("treesitter-config")
require("cheat-sh-config")
require("lsp-and-completion")
require("linter")
require("appearance") -- should come after gui settings

