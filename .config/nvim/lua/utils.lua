opt = vim.opt -- global option
g = vim.g -- global variable
api = vim.api
fn = vim.fn
cmd = vim.cmd
bo = vim.bo -- buffer-scoped options
b = vim.b -- buffer-scoped variables
augroup = vim.api.nvim_create_augroup
autocmd = vim.api.nvim_create_autocmd
telescope = require("telescope.builtin") -- requires loading extensions first
keymap = vim.keymap.set
home = fn.expand("~") ---@diagnostic disable-line: missing-parameter

pp = vim.pretty_print
