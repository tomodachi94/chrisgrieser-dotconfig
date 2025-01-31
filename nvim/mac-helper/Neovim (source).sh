#!/usr/bin/env zsh
export PATH=/usr/local/lib:/usr/local/bin:/opt/homebrew/bin/:$PATH
# INFO: workaround for: https://github.com/neovide/neovide/issues/1586
# this script, bundles as .app via Automator, ensures you can open a file from
# anywhere in macOS and it will open in the currently existing Neovide instance

file="$1"
[[ -n "$LINE" ]] && LINE="+$LINE" # $LINE is set via `open --env=LINE=num`

if pgrep "neovide"; then
	echo "cmd[[edit $LINE $file]]" >"/tmp/nvim-automation" # this part requires the setup in /lua/file-watcher.lua
	osascript -e 'tell application "Neovide" to activate'
else
	# shellcheck disable=2086
	neovide $LINE "$file"
fi
