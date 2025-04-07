DOTHOME=$(dirname ${(%):-%N})
source $DOTHOME/.shell_alias
source $DOTHOME/.git_alias

bindkey "^[[H" "beginning-of-line"
bindkey "^[[F" "end-of-line"
bindkey "^[^[[D" "backward-word"
bindkey "^[^[[C" "forward-word"
bindkey "^[[1;5D" "backward-word"
bindkey "^[[1;5C" "forward-word"
bindkey "^[[3;5~" "kill-word"
bindkey "^H" "backward-kill-word"

export WORDCHARS='*?_-.[]~=&;!#$%^(){}<>'

export HOST=$HOST

if [[ -d /opt/homebrew/opt/findutils/libexec/gnubin ]]; then
    addpath /opt/homebrew/opt/findutils/libexec/gnubin prefix
fi

ZCOLOR_RED='%{%B%F{red}%}'
ZCOLOR_BLUE='%{%B%F{blue}%}'
ZCOLOR_GREEN='%{%b%F{green}%}'
ZCOLOR_BGREEN='%{%B%F{green}%}'
ZCOLOR_WHITE='%{%B%F{white}%}'
ZCOLOR_ORANGE='%{%b%F{orange}%}'
ZCOLOR_NONE='%{%b%f%}' 
ZSH_NEWLINE=$'\n'
USER_COLOR="${ZCOLOR_NONE}"
declare -A USER_COLOR
USER_COLOR[$USER]=${ZCOLOR_GREEN}
USER_COLOR[root]=${ZCOLOR_RED}
USER_COLOR[ec2-user]=${ZCOLOR_ORANGE}

function updatePS1 {
    EXITCODE=$?
    [ $EXITCODE != 0 ] && EXIT_SUFFIX=":${ZCOLOR_RED}$EXITCODE${ZCOLOR_NONE}" || EXIT_SUFFIX="${ZCOLOR_NONE}";
    PS1="${USER_COLOR[$USER]}%n${ZCOLOR_NONE}@${ZCOLOR_ORANGE}%m ${ZCOLOR_BLUE}%~${EXIT_SUFFIX}${ZSH_NEWLINE}$ "
}
precmd() { updatePS1; }

if [[ -e $HOME/.pyenv ]]; then
  export PYENV_ROOT="$HOME/.pyenv"
  [[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init -)"
fi

if [[ -e $HOME/.cargo/env ]]; then
  source $HOME/.cargo/env
fi

eval "$(lessfile)"
