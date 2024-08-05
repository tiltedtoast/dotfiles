if status is-interactive
    oh-my-posh init fish --config $HOME/powerline_custom.omp.json | source
    zoxide init --cmd cd fish | source
end

set fish_greeting ""

fish_add_path "$HOME/.local/bin"
fish_add_path "$HOME/bin"
fish_add_path /usr/local/bin
fish_add_path "$HOME/go/bin"
fish_add_path /usr/local/cuda/bin

fish_add_path "$HOME/3rd-party/depot_tools"
fish_add_path /usr/local/go/bin /usr/bin/FlameGraph

# volta
set -x VOLTA_HOME "$HOME/.volta"
set -x VOLTA_FEATURE_PNPM 1
fish_add_path "$VOLTA_HOME/bin"

# zvm
fish_add_path "$HOME/.zvm/bin"
fish_add_path "$ZVM_INSTALL"
set -x ZVM_INSTALL "$HOME/.zvm/self"

# bun
set -x BUN_INSTALL "$HOME/.bun"
fish_add_path "$BUN_INSTALL/bin"

# pnpm
set -x PNPM_HOME "$HOME/.local/share/pnpm"
fish_add_path "$PNPM_HOME"
# pnpm end


set -x EDITOR code

alias ls=eza
alias l='eza -laah --colour=always --icons=always --group-directories-first -s name --time-style "+%d %b %y %X"'
alias s='source $HOME/.config/fish/config.fish'
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
alias update="sudo nala upgrade -y"

function gfomo
    set main_branch (git symbolic-ref refs/remotes/origin/HEAD | cut -d'/' -f4)
    git fetch origin $main_branch
    git merge origin/$main_branch
end

function watch_mode
    fd -t file --search-path $argv | entr (which (ps -p $fish_pid -o comm=)) -c $argv
end

function cargo-new
    cargo new --bin $argv[1]
    cd $argv[1]
    cargo add anyhow
    code .
end

function cargo-new-tokio
    cargo new --bin $argv[1]
    cd $argv[1]
    cargo add tokio --features="full"
    cargo add anyhow
    code .
end

set -x CC clang

bind \cH backward-kill-word # Ctrl + Backspace
bind \e\[3\;5~ kill-word


# modular
set -x MODULAR_HOME "$HOME/.modular"
fish_add_path "$MODULAR_HOME/pkg/packages.modular.com_mojo/bin"
fish_add_path "$HOME/.dotnet" "$HOME/.dotnet/tools"

# wasmer
set -x WASMER_DIR "$HOME/.wasmer"

set -x CXX clang++

fish_add_path "$HOME/.turso"
fish_add_path "$HOME/.cache/rebar3/bin"

set -x DENO_INSTALL "$HOME/.deno"
fish_add_path "$DENO_INSTALL/bin"

set -x JAVA_HOME "$HOME/3rd-party/graalvm"
fish_add_path "$JAVA_HOME/bin"
fish_add_path "$HOME/.local/share/coursier/bin"

fish_add_path "$HOME/.cargo/bin"

set -x LD_LIBRARY_PATH "/usr/local/lib:/usr/local/cuda/lib64:$LD_LIBRARY_PATH"
set -x LD /usr/local/bin/mold

fish_add_path "$HOME/3rd-party/swift/usr/bin"

ip a | rg eth2 &>/dev/null && ip link set dev eth2 mtu 1350 &>/dev/null
pgrep -f wait-forever.sh >/dev/null || nohup ./wait-forever.sh &>/dev/null
