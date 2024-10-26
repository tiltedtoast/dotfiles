setopt appendhistory
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt INTERACTIVE_COMMENTS
unsetopt BEEP

if [[ ! "$fpath" =~ .*"$HOME/.zsh/completions".* ]]; then
  fpath=(~/.zsh/completions $fpath)
fi

autoload -Uz compinit && compinit

# Enable case-insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# Enable completions with sudo
zstyle ':completion::complete:*' gain-privileges 1

# Close shell with ctrl+d regardless of if the command line is empty or not
exit_zsh() { exit }
zle -N exit_zsh
bindkey '^D' exit_zsh

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.zsh"

eval "$(direnv hook zsh)"
eval "$(oh-my-posh init zsh --config $HOME/powerline_custom.omp.json)"
eval "$(zoxide init --cmd cd zsh)"
eval "$(atuin init --disable-up-arrow zsh)"



# Fix paste being super slow
pasteinit() {
  OLD_SELF_INSERT=${${(s.:.)widgets[self-insert]}[2,3]}
  zle -N self-insert url-quote-magic # I wonder if you'd need `.url-quote-magic`?
}

pastefinish() {
  zle -N self-insert $OLD_SELF_INSERT
}

zstyle :bracketed-paste-magic paste-init pasteinit
zstyle :bracketed-paste-magic paste-finish pastefinish




source $HOME/.zsh/aliases.sh


if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    if [[ "$ID" == "ubuntu" ]]; then
        source $HOME/.zsh/ubuntu_specific.sh
    elif [[ "$ID" == "arch" ]]; then
        source $HOME/.zsh/arch_specific.sh
    fi
fi

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

bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word
bindkey '^H' backward-kill-word  # Ctrl + Backspace
bindkey '^[[3;5~' kill-word      # Ctrl + Delete
bindkey "^[[3~"  delete-char




source $HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
source $HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Wasmer



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

export SURFSHARK_ADAPTERS=(eth0 eth2)

if [ -n "$WSL_INTEROP" ]; then
    for adapter in ${SURFSHARK_ADAPTERS[@]}; do
        ip a | rg $adapter &> /dev/null && sudo ip link set dev $adapter mtu 1350 &> /dev/null
    done
    export $(dbus-launch)
    export GALLIUM_DRIVER=d3d12
    (command -v opam >/dev/null 2>&1 && eval $(opam env)) >/dev/null 2>&1 || true

    if [[ ! -e ~/.local/bin/explorer.exe ]]; then
      ln -s /mnt/c/windows/explorer.exe ~/.local/bin/explorer.exe
    fi

    if [[ ! -e ~/.local/bin/code ]]; then
        ln -s "/mnt/c/Users/tim/AppData/Local/Programs/Microsoft VS Code/bin/code" ~/.local/bin/code
    fi

    if [[ ! -e ~/.local/bin/ssh ]]; then
        ln -s "/mnt/c/windows/system32/openssh/ssh.exe" ~/.local/bin/ssh
    fi

    if [[ ! -e ~/.local/bin/ssh-add ]]; then
        ln -s "/mnt/c/windows/system32/openssh/ssh-add.exe" ~/.local/bin/ssh-add
    fi

    if [[ ! -e ~/.local/bin/op-ssh-sign-wsl ]]; then
        ln -s "/mnt/c/Users/tim/AppData/Local/1Password/app/8/op-ssh-sign-wsl" ~/.local/bin/op-ssh-sign-wsl
    fi

    alias op="/mnt/c/Users/tim/scoop/shims/op.exe"
    alias ssh="/mnt/c/windows/system32/openssh/ssh.exe"
    alias ssh-add="/mnt/c/windows/system32/openssh/ssh-add.exe"
fi

pgrep -f wait-forever.sh > /dev/null || nohup ./wait-forever.sh &> /dev/null &!




[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"



. "$HOME/.cargo/env"

# bun completions
[ -s "/home/tim/.bun/_bun" ] && source "/home/tim/.bun/_bun"
