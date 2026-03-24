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
export LS_COLORS='no=00:fi=00:di=00;34:ln=01;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.gz=01;31:*.bz2=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.avi=01;35:*.fli=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.ogg=01;35:*.mp3=01;35:*.wav=01;35:*.xml=00;31:'

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

function cht() { curl -m 7 "http://cheat.sh/$1"; }
alias linutil="curl -fsSL https://christitus.com/linux | sh"

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
fastfetch
eval "$(ssh-agent -s)"
