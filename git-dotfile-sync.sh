#!/bin/zsh

cd "$(dirname "$0")" || exit 1

device_name=$(scutil --get ComputerName | cut -d" " -f2-)
filesChanged="$(git status --porcelain | wc -l | tr -d ' ')"

if [[ "$filesChanged" == 0 ]] ; then
	git pull
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

msg="$changeType, $device_name"
git add -A && git commit -m "$msg" --author="🤖<automated@cron.job>"
git pull
git push

# Alfred Repos pullen
if [[ "$1" == "wake" ]] ; then
	cd "Alfred.alfredpreferences/workflows" || exit 1
	cd "./shimmering-obsidian" && git pull
	cd "../alfred-bibtex-citation-picker" && git pull
	cd "../pdf-annotation-extractor-alfred" && git pull
fi
