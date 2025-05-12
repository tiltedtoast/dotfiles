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



create_man_wrapper() {
    local man_path=$(command -v man)
    eval "
    man() {
        $man_path \"\$@\" | bat --language=Manpage --style=plain
    }
    "
}

create_man_wrapper



create_mold_wrapper() {
    local tool=$1
    local tool_path=$(command -v "$tool")
    eval "
    __mold_wrapped_$tool() {
        mold -run '$tool_path' \"\$@\"
    }
    "
}

# Create wrappers for build tools
build_tools=(make cmake ninja)
for tool in "${build_tools[@]}"; do
    create_mold_wrapper "$tool"
    alias "$tool"="__mold_wrapped_$tool"
done


alias -g -- -h='-h 2>&1 | bat --language=help --style=plain --paging=never --theme="OneDark"'
alias -g -- --help='--help 2>&1 | bat --language=help --style=plain --paging=never --theme="OneDark"'
