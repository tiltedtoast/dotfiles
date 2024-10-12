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

function man
    /usr/bin/man $argv | bat --language=Manpage --style=plain
end

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

function create_mold_wrapper
    set -l tool $argv[1]
    set -l tool_path (command -v $tool)

    eval "
    function __mold_wrapped_$tool
        mold -run '$tool_path' \$argv
    end
    "
end

# Create wrappers for build tools
set -l build_tools make cmake ninja
for tool in $build_tools
    create_mold_wrapper $tool
    alias $tool="__mold_wrapped_$tool"
end
