---@diagnostic disable: lowercase-global

-- shorthands
opt = vim.opt
g = vim.g
api = vim.api
fn = vim.fn
cmd = vim.cmd

-- common functions
function keymap (modes, key, result)
	if #modes < 2 then -- < 2 to account for empty mode (= :map)
		vim.keymap.set(modes, key, result)
	else
		-- set for every mode in the mode-arg
		for i=1, #modes do
			local mode = modes:sub(i, i)
			vim.keymap.set(mode, key, result)
		end
	end
end

function autocmd(eventName, callbackFunction)
	vim.api.nvim_create_autocmd(eventName, { callback = callbackFunction })
end

