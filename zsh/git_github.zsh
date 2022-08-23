# git log
alias gl="git log --graph --pretty=format:'%C(yellow)%h%C(red)%d%C(reset) %s %C(green)(%ch) %C(bold blue)<%an>%C(reset)'"

# git log (interactive)
function gli (){
	local COMMIT
	COMMIT=$(git log --color=always --pretty=format:'%C(yellow)%h%C(reset) %s' | \
	   fzf -0 \
		--ansi \
		--layout=reverse \
		--no-sort \
		--query="$1" \
		--no-info \
		--header-first --header="↵ : checkout   ^H: copy [h]ash" \
		--preview-window="wrap" \
		--bind="ctrl-h:execute-silent(echo {} | cut -d' ' -f1 | pbcopy)+abort" \
		--preview="echo {} | cut -d' ' -f1 | xargs git show --name-only --color=always --pretty=format:'%C(yellow)%h %C(red)%D %n%C(blue)%an %C(green)(%ch) %n%n%C(reset)%C(bold)%s %n%C(reset)%C(magenta)'"\
	)
	[[ -z "$COMMIT" ]] && return 0
	# output hash
	local hash
	hash=$(echo "$COMMIT" | cut -d' ' -f1)
	git checkout "$hash"
}

# git add, commit, (pull) & push
function acp (){
	# safeguard against accidental pushing of large files
	NUMBER_LARGE_FILES=$(find . -not -path "**/.git/**" -size +10M | wc -l | xargs)
	if [[ $NUMBER_LARGE_FILES -gt 0 ]]; then
		echo -n "$NUMBER_LARGE_FILES Large files detected, aborting automatic git sync."
		exit 1
	fi

	local COMMIT_MSG="$*"
	local MSG_LENGTH=${#COMMIT_MSG}
	if [[ $MSG_LENGTH -gt 50 ]]; then
		echo "Commit Message too long ($MSG_LENGTH chars)."
		# shellcheck disable=SC1087,SC2154
		FUNC_NAME="$funcstack[1]" # https://stackoverflow.com/a/62527825
		print -z "$FUNC_NAME \"$COMMIT_MSG\"" # put back into buffer
		return 1
	fi
	if [[ "$COMMIT_MSG" == "" ]] ; then
		COMMIT_MSG="patch"
	fi

	git add -A && git commit -m "$COMMIT_MSG"
	git pull
	git push
}

function amend () {
	local COMMIT_MSG="$*"
	local LAST_COMMIT_MSG
	LAST_COMMIT_MSG=$(git log -1 --pretty=%B | head -n1)
	local MSG_LENGTH=${#COMMIT_MSG}
	if [[ $MSG_LENGTH -gt 50 ]]; then
		echo "Commit Message too long ($MSG_LENGTH chars)."
		print -z "\"$COMMIT_MSG\""
		return 1
	fi
	if [[ "$COMMIT_MSG" == "" ]] ; then
		# prefile last commit message
		print -z "amend \"$LAST_COMMIT_MSG\""
		return 0
	else
		git commit --amend -m "$COMMIT_MSG" # directly set new commit message
	fi
	# ⚠️ only when working alone – might lead to conflicts when working
	# with collaboraters: https://stackoverflow.com/a/255080
	git push --force
}

function gittree(){
	(
		r=$(git rev-parse --git-dir) && r=$(cd "$r" && pwd)/ && cd "${r%%/.git/*}"
		command exa --long --git --git-ignore --no-user --no-permissions --no-time --no-filesize --ignore-glob=.git --tree --color=always | grep -v "\--"
	)
}

alias gc="git checkout"
alias add="git add -A"
alias commit="git commit -m"
alias push="git push"
alias pull="git pull"
alias ignored="git status --ignored"

# go to git root https://stackoverflow.com/a/38843585
alias g='r=$(git rev-parse --git-dir) && r=$(cd "$r" && pwd)/ && cd "${r%%/.git/*}"'
alias gs='git status'
alias gt='gittree'

# open GitHub repo
alias gh="open \$(git remote -v | grep git@github.com | grep fetch | head -n1 | cut -f2 | cut -d' ' -f1 | sed -e's/:/\//' -e 's/git@/https:\/\//' -e 's/\.git//' );"
alias ghi="open \$(git remote -v | grep git@github.com | grep fetch | head -n1 | cut -f2 | cut -d' ' -f1 | sed -e's/:/\//' -e 's/git@/https:\/\//' -e 's/\.git//' )/issues;"

function clone(){
	git clone "$*"
	# shellcheck disable=SC2012
	z "$(ls -1 -t | head -n1)" || return

	grep -q "obsidian" package.json &> /dev/null && npm i # if it's an Obsidian plugin
}

function sclone(){
	git clone --depth=1 "$*"
	# shellcheck disable=SC2012
	z "$(ls -1 -t | head -n1)" || return

	grep -q "obsidian" package.json &> /dev/null && npm i # if it's an Obsidian plugin
}

function nuke {
	SSH_REMOTE=$(git remote -v | head -n1 | cut -d" " -f1 | cut -d$'	' -f2)

	# go to git repo root
	# shellcheck disable=SC2164
	r=$(git rev-parse --git-dir) && r=$(cd "$r" && pwd)/ && cd "${r%%/.git/*}"
	LOCAL_REPO=$(pwd)
	cd ..

	rm -rf "$LOCAL_REPO"
	echo "---"
	echo "Local repo removed."
	echo
	echo "Downloading repo again from remote…"
	echo "---"

	git clone "$SSH_REMOTE"
	cd "$LOCAL_REPO" || return 1
}

# runs a release scripts placed at the git root
function rel(){
	# shellcheck disable=SC2164
	r=$(git rev-parse --git-dir) && r=$(cd "$r" && pwd)/ && cd "${r%%/.git/*}"
	if [[ -f .release.sh ]] ; then
		zsh .release.sh "$*"
	else
		echo "No '.release.sh' found."
	fi
}

