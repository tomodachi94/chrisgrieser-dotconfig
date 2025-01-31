# Quick Open File/Folder
# requires: exa, bat, zoxide, fd, fzf
function o (){
	local selected
	local input="$*"

	if [[ -e "$input" ]] ; then # skip `fzf` if file is fully named, e.g. through tab completion
		[[ -d "$input" ]] && z "$input"
		[[ -f "$input" ]] && open "$input"
		return 0
	fi
	# --delimiter and --nth options ensure only file name and parent folder are displayed
	selected=$(fd --hidden --color=always | fzf \
					-0 -1 \
					--ansi \
					--query="$input" \
					--expect=ctrl-b \
					--cycle \
					--info=inline \
					--delimiter=/ --with-nth=-2.. --nth=-2.. \
					--header-first \
					--header="↵ : open/cd, ^B: buffer, ↹ : only dirs" \
					--bind="tab:reload(fd --hidden --color=always --type=directory)+change-prompt(↪ )" \
					--preview-window="border-left" \
					--preview 'if [[ -d {} ]] ; then echo "\\033[1;33m"{}"\\033[0m" ; echo ; exa  --icons --oneline {} ; else ; bat --color=always --style=snip --wrap=never --tabs=1 {} ; fi' \
				)
	[[ -z "$selected" ]] && return 0
	key_pressed=$(echo "$selected" | head -n1)
	selected=$(echo "$selected" | tail -n+2)

	if [[ "$key_pressed" == "ctrl-b" ]] ; then
		print -z "$selected"
	elif [[ -d "$selected" ]] ; then
		z "$selected"
	elif [[ -f "$selected" ]] ; then
		open "$selected"
	fi
}

function directoryInspect (){
	if command git rev-parse --is-inside-work-tree &>/dev/null ; then
		git status --short
		echo
	fi
	if [[ $(ls | wc -l) -lt 20 ]] ; then
		exa
	fi
}

# measure zsh loading time, https://blog.jonlu.ca/posts/speeding-up-zsh
function timezsh(){
	for i in $(seq 1 10); do /usr/bin/time $SHELL -i -c exit; done
}

# no arg = all files in folder will be deleted
function d () {
	if [[ $# == 0 ]]; then
		IFS=$'\n'
		# shellcheck disable=SC2207
		ALL_FILES=($(find . -not -name ".*"))
		unset IFS
	else
		ALL_FILES=( "$@" ) # save files as array
	fi
	for item in "${ALL_FILES[@]}"; do
		local itemInTrash="$HOME/.Trash/$(basename "$item")"
		[[ -e "$itemInTrash" ]] && rm -r
		mv "$item" "$itemInTrash"
	done
}

# draws a separator line with terminal width
function separator (){
	local SEP=""
	terminal_width=$(tput cols)
	for (( i = 0; i < terminal_width; i++ )); do
		SEP="$SEP─"
	done
	echo "$SEP"
}

# smarter z/cd
# (also alternative to https://blog.meain.io/2019/automatically-ls-after-cd/)

function z () {
	if [[ -f "$1" ]] ; then
		__zoxide_z "$(dirname "$1")"
	else
		__zoxide_z "$1"
	fi
	[[ $? -eq 0 ]] && directoryInspect
}
function zi () {
	__zoxide_zi
	directoryInspect
}

# settings (zshrc)
alias ,="settings"
function settings () {
	( cd "$DOTFILE_FOLDER/zsh" || return
	# shellcheck disable=SC1009,SC1056,SC1073,SC2035
	SELECTED=$( { ls *.zsh | cut -d. -f1 ; ls .z* } | fzf \
	           -0 -1 \
	           --query "$*" \
	           --height=75% \
	           --layout=reverse \
	           --info=hidden \
	           )
	if [[ -n $SELECTED ]] ; then
		[[ $SELECTED != .z* ]] && SELECTED="$SELECTED.zsh"
		open "$SELECTED"
	fi )
}

# copies last commands
function lc (){
	history | tail -n1 | cut -c8- | sed 's/"/\\\"/g' | sed "s/'/\\\'/g" | xargs | pbcopy
	echo "Copied."
}

# copies result of last command
function lr (){
	last_command=$(history | tail -n 1 | cut -c 8-)
	echo -n "$(eval "$last_command")" | pbcopy
	echo "Copied."
}

# extract function
function ex () {
	if [[ -f $1 ]] ; then
		case $1 in
			*.tar.bz2)   tar -xjf "$1"   ;;
			*.tar.gz)    tar -xzf "$1"   ;;
			*.tar.zsr)    tar --use-compress-program=unzstd -xvf "$1" ;;
			*.rar)       unrar -e "$1"   ;;
			*.gz)        gunzip "$1"     ;;
			*.tar)       tar -xf "$1"    ;;
			*.tbz2)      tar -xjf "$1"   ;;
			*.tgz)       tar -xzf "$1"   ;;
			*.zip)       unzip "$1"      ;;
			*.Z)         uncompress "$1" ;;
			*) echo "'$1' cannot be extracted via ´ex´" ;;
		esac
	else
		echo "'$1' is not a valid file"
	fi
}

# appid of macOS apps
function appid () {
	local id
	id=$(osascript -e "id of app \"$1\"")
	echo "appid: $id"
	echo "$id" | pbcopy
}

# Conversions
# using `explode` to expand anchors & aliases: https://mikefarah.gitbook.io/yq/operators/anchor-and-alias-operators#explode-alias-and-anchor
function yaml2json () {
	file_name=${1%.*} # remove extension
	yq -o=json 'explode(.)' "$1" > "${file_name}.json"
}

function json2yaml () {
	yq -P '.' "$1" > "$(basename "$1" .json).yml"
}
