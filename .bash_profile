export PS1='\[\e[1;31m\][ \[\e[m\]\[\e[1;36m\]\u:\[\e[m\]\[\e[0;34m\]\W\[\e[m\]\[\e[1;31m\] ]\[\e[m\]\[\e[1;31m\]~> \[\e[m\]\[\e[0m\]'
# export PS1='\[\e[1;37m\][\[\e[m\] \[\e[0;32m\]\u:\[\e[m\] \[\e[0;34m\]\W\[\e[m\] \[\e[1;37m\]]\[\e[m\] \[\e[1;31m\]~> \[\e[m\]\[\e[0m\]'
# export PS1='\[\e[1;37m\]\u:\[\e[m\] \[\e[1;34m\]\W\[\e[m\] \[\e[1;31m\]### \[\e[m\]\[\e[0m\]'

# export NODE_ENV=production
export PATH=/usr/local/bin:$PATH
export EDITOR=vim
export CLICOLOR=1
export GREP_OPTIONS='--color=auto'
# export LSCOLORS=GxFxCxDxBxegedabagaced

# alias
#alias ls='ls -laF'
#alias mkdir='mkdir -pv'
#alias cp='cp -i'
#alias mv='mv -i'
#alias rm='rm -i'
eval "$(/opt/homebrew/bin/brew shellenv)"
export PATH="/opt/homebrew/opt/python@3.10/bin:$PATH"
