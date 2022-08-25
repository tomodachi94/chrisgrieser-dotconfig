#!/bin/zsh
# "--submodules" → also pull submodules

cd "$(dirname "$0")" || exit 1
device_name=$(scutil --get ComputerName | cut -d" " -f2-)
filesChanged="$(git status --porcelain | wc -l | tr -d ' ')"

if [[ "$filesChanged" == 0 ]] ; then
	git pull
	[[ "$1" == "--submodules" ]] && git submodule update --remote --rebase # --rebase ensures that there is no detached head in the submodules
	exit 0
elif [[ "$filesChanged" == 1 ]] ; then
	changeType="$filesChanged file"
else
	changeType="$filesChanged files"
fi

# safeguard against accidental pushing of large files
NUMBER_LARGE_FILES=$(find . -not -path "**/.git/**" -size +10M | wc -l | xargs)
if [[ $NUMBER_LARGE_FILES -gt 0 ]]; then
	echo -n "$NUMBER_LARGE_FILES Large files detected, aborting automatic git sync."
	exit 1
fi

# git add-commit-pull-push sequence
msg="$device_name ($changeType)"
git add -A && git commit -m "$msg" --author="🤖 automated<cron@job>"
git pull
[[ "$1" == "--submodules" ]] && git submodule update --remote
git push

# check that everything worked (e.g. submodules are dirty)
DIRTY=$(git status --porcelain)
if [[ -n "$DIRTY" ]]; then
	echo "Dotfile Repo still dirty."
	echo "$DIRTY"
	exit 1
fi
