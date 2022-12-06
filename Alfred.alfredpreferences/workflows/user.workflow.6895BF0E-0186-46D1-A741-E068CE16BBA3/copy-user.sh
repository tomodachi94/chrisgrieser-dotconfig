#!/usr/bin/env zsh
export PATH=/usr/local/lib:/usr/local/bin:/opt/homebrew/bin/:$PATH

pass show 
data=$(pass show "$*" | grep -i "user:" | cut -d: -f1)
if [[ -z "$data" ]]; then
	echo "no data, only password"
else
	echo "$data" | pbcopy
	echo "$data" # for Large Type
fi
