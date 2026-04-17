#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'

# PS1='[\u@\h \W]\$ '

export PS1='$(git branch &>/dev/null; if [ $? -eq 0 ]; then \
echo "\[\e[1m\]\u@\h\[\e[0m\]: \w [\[\e[34m\]$(git branch | grep ^* | sed s/\*\ //)\[\e[0m\]\
$(echo `git status` | grep "nothing to commit" > /dev/null 2>&1; if [ "$?" -ne "0" ]; then \
echo "\[\e[1;31m\]*\[\e[0m\]"; fi)] \$ "; else \
echo "\[\e[1m\]\u@\h\[\e[0m\]: \w \$ "; fi )'

export HISTFILESIZE=10000
export HISTSIZE=500
export HISTTIMEFORMAT="%F %T"

shopt -s checkwinsize
shopt -s histappend

export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"
export EDITOR=nvim

export CLICOLOR=1

LS_COLORS='di=1;32:ln=1;30;47:so=30;45:pi=30;45:ex=1;31:bd=30;46:cd=30;46:su=30'
LS_COLORS="${LS_COLORS};41:sg=30;41:tw=30;41:ow=30;41:*.rpm=1;31:*.deb=1;31"
LSCOLORS=CxahafafBxagagabababab

export LESS_TERMCAP_mb=$'\E[01;31m'
export LESS_TERMCAP_md=$'\E[01;31m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[01;44;33m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[01;32m'

alias yayf="yay -Slq | fzf --multi --preview 'yay -Sii {1}' --preview-window=down:75% | xargs -ro yay -S"
alias pacf="pacman -Slq | fzf --multi --preview 'pacman -Si --color=always {1}' --preview-window=down:75% | xargs -ro sudo pacman -S"
alias flatf="flatpak remote-ls --app --columns=name,application flathub | fzf --multi --preview 'flatpak remote-info flathub {-1}' --preview-window=down:75% | awk '{print \$NF}' | xargs -ro flatpak install -y flathub"
alias pacrm="pacman -Qeq | fzf --multi --preview 'pacman -Qi {1}' --preview-window=down:75% | xargs -ro sudo pacman -Rns"
alias flatrm="flatpak list --app --columns=name,application | fzf --multi --preview 'flatpak info {-1}' --preview-window=down:75% | awk '{print \$NF}' | xargs -ro flatpak uninstall -y"
alias sysupdate="topgrade && pacman -Qtdq | xargs -r sudo pacman -Rns && sudo pacman -Sc --noconfirm"


function cht() { curl -m 7 "http://cheat.sh/$1"; }
alias linutil="curl -fsSL https://christitus.com/linux | sh"
alias zed="zeditor"
alias ll="ls -lah"
alias clearf="clear;fastfetch"

eval "$(fzf --bash)"
export FZF_DEFAULT_OPTS="--height 50% --layout=reverse --border --inline-info"
export FZF_DEFAULT_COMMAND="fd --type f --hidden --exclude .git --exclude node_modules"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always --line-range :500 {}' --preview-window=right:60%"

export FZF_ALT_C_COMMAND="fd --type d --hidden --exclude .git --exclude node_modules"
export FZF_ALT_C_OPTS="--preview 'eza --tree --level=2 --icons=always --color=always {} | head -200' --preview-window=right:60%"

eval "$(starship init bash)"
eval $(keychain --eval id_ed25519) # for ssh agent

eval "$(zoxide init bash)"
alias cd="z"
clearf
