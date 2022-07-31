# shellcheck disable=SC2139
# https://www.thorsten-hans.com/5-types-of-zsh-aliases

# configurations
alias .star='open $STARSHIP_CONFIG'

# z & cd
alias zz='z -' # back
alias .="open ."
alias ..="z .."
alias ...="z ../.."
alias ....="z ../../.."
alias ov='cd "$VAULT_PATH"' # Obsidian Vault

# utils
alias q='exit'
alias notify="osascript -e 'display notification \"\" with title \"Terminal Process finished.\" subtitle \"\" sound name \"\"'"
alias urlencode='node --eval "console.log(encodeURIComponent(process.argv[1]))"'
alias t="alacritty-theme-switch"

# colorize by default
alias grep='grep --color'
alias ls='ls -G'

# Safety nets
alias rm='rm -i'
alias mv='mv -i'
alias ln='ln -i'

# defaults
alias which='which -a'
alias mkdir='mkdir -p'
alias pip="pip3"

# exa
alias exall='exa --all --long --git --icons --group-directories-first --sort=modified'
alias ll='exa --all --long --git --icons --group-directories-first --sort=modified'
alias exa='exa --all --icons --group-directories-first --sort=modified --ignore-glob=.DS_Store'
alias exagit='git status --short; echo; exa --long --grid --git --git-ignore --no-user --no-permissions --no-time --no-filesize --ignore-glob=.git'
alias tree='exa --tree -L2'
alias treee='exa --tree -L3'
alias treeee='exa --tree -L4'
alias treeeee='exa --tree -L5'
alias size="du -sh ./* | sort -rh | sed 's/\\.\\///'" # size of files in current directory

# Suffix Aliases
# = default command to act upon the filetype, when is is entered
# without preceding command (analogous to `setopt AUTO_CD` but for files)
alias -s {css,ts,js,yml,json,plist,xml,md}='bat'
alias -s {pdf,png,jpg,jpeg}="qlmanage -p"

# open log files in less and scrolled to the bottom
alias -s log="less +G"
