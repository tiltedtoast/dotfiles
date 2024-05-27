HISTFILE=$HOME/.zsh_history
HISTSIZE=500000
SAVEHIST=500000
setopt appendhistory
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY

# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:/usr/local/bin:$PATH
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"
export PATH="/usr/local/cuda/bin:$PATH"
export ZVM_INSTALL="$HOME/.zvm/self"
export PATH="$PATH:$HOME/.zvm/bin"
export PATH="$PATH:$ZVM_INSTALL/"

autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.zsh"

eval "$(oh-my-posh init zsh --config $HOME/powerline_custom.omp.json)"
eval "$($(which zoxide) init --cmd cd zsh)"

export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"
export VOLTA_FEATURE_PNPM=1


# bun
export BUN_INSTALL="$HOME/.bun"
export PATH=$BUN_INSTALL/bin:$PATH

# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"
# pnpm end

export PATH=$PATH:/usr/local/go/bin

export PATH=$PATH:/usr/bin/FlameGraph

[ -f "$HOME/.ghcup/env" ] && source "$HOME/.ghcup/env" # ghcup-envexport

pasteinit() {
  OLD_SELF_INSERT=${${(s.:.)widgets[self-insert]}[2,3]}
  zle -N self-insert url-quote-magic # I wonder if you'd need `.url-quote-magic`?
}

pastefinish() {
  zle -N self-insert $OLD_SELF_INSERT
}

zstyle :bracketed-paste-magic paste-init pasteinit
zstyle :bracketed-paste-magic paste-finish pastefinish

bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word

TIMEFMT=$'real\t%E\nuser\t%U\nsys\t%S'

export EDITOR='code'

alias ls=eza
alias l='eza -laah --colour=always --icons=always --group-directories-first -s name --time-style "+%d %b %y %X"'
alias s='source $HOME/.zshrc'
alias c=clear
alias gst='git status'
alias rgi='rg --ignore-case'
alias cat='bat --theme "OneDark" --paging=never'
alias gcam='git add . && git commit -m'
alias gam='git add --all && git commit --amend --no-edit'
alias gc='git commit -m'
alias gco='git checkout'
alias gp='git push'
alias gpl='git pull'
alias gsta='git stash'
alias rgi='rg --ignore-case'
alias wiki='wiki-tui'
alias drs='danbooru-rs'
alias dgo='danbooru-go'
alias cnew=cargo-new
alias cnewtokio=cargo-new-tokio
alias cb='cargo build'
alias cbr='cargo build --release'
alias cr='cargo run'
alias crr='cargo run --release'
alias cip='cargo install --path .'
alias ci='cargo install'
alias where='which'
alias e=explorer.exe
alias watch=watch_mode
alias code='code -r'
alias suggest="gh copilot suggest"
alias explain="gh copilot explain"
alias update="sudo apt update && sudo apt upgrade -y"
gfomo() {
    main_branch=$(git symbolic-ref refs/remotes/origin/HEAD | cut -d'/' -f4)
    git fetch origin $main_branch &&
    git merge origin/$main_branch;
}

watch_mode() {
    fd -t file --search-path $1 | entr $(which $(ps -p $$ -o comm=)) -c $2
}

function cargo-new {
    cargo new --bin $1
    cd $1
    cargo add anyhow
    code .
}

function cargo-new-tokio {
    cargo new --bin $1
    cd $1
    cargo add tokio --features="full"
    cargo add anyhow
    code .
}

export CC="clang"

bindkey '^H' backward-kill-word  # Ctrl + Backspace
bindkey '^[[3;5~' kill-word      # Ctrl + Delete

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
export MODULAR_HOME="$HOME/.modular"
export PATH="$HOME/.modular/pkg/packages.modular.com_mojo/bin:$PATH"

export PATH="$HOME/.dotnet/:$HOME/.dotnet/tools:$PATH"

export ZSH_COMPDUMP=$ZSH/cache/.zcompdump-$HOST

alias -g -- -h='-h 2>&1 | bat --language=help --style=plain --paging=never --theme="OneDark"'
alias -g -- --help='--help 2>&1 | bat --language=help --style=plain --paging=never --theme="OneDark"'


source $HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
source $HOME/.zsh/zsh-colored-man-pages/colored-man-pages.plugin.zsh
source $HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Wasmer
export WASMER_DIR="$HOME/.wasmer"
[ -s "$WASMER_DIR/wasmer.sh" ] && source "$WASMER_DIR/wasmer.sh"
setopt interactivecomments
export CXX=clang++

# Turso
export PATH="$HOME/.turso:$PATH"

export PATH="$HOME/.cache/rebar3/bin:$PATH"
export DENO_INSTALL="$HOME/.deno"
export PATH=$HOME/.deno/bin:$PATH

export JAVA_HOME="$HOME/3rd-party/graalvm"
export PATH="$JAVA_HOME/bin:$PATH"
export PATH="/home/tim/.local/share/coursier/bin:$PATH"
. "$HOME/.cargo/env"

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('$HOME/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]; then
        . "$HOME/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="$HOME/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

export LD_LIBRARY_PATH="/usr/local/cuda/lib64:$LD_LIBRARY_PATH"
export LD=/usr/local/bin/mold
