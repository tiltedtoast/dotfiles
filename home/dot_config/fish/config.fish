if status is-interactive
    oh-my-posh init fish --config $HOME/powerline_custom.omp.json | source
    zoxide init --cmd cd fish | source
    atuin init --disable-up-arrow fish | source
end

set fish_greeting ""

source $HOME/.config/fish/env.fish
source $HOME/.config/fish/aliases.fish

bind \cd exit

function read_os_release
    if test -f /etc/os-release
        for line in (cat /etc/os-release)
            set -l key (string split -m 1 '=' $line)[1]
            set -l value (string split -m 1 '=' $line)[2]
            # Remove quotes if present
            set value (string trim -c '"' $value)
            set -gx $key $value
        end
    end
end

read_os_release

if set -q ID
    switch "$ID"
        case ubuntu
            source $HOME/.config/fish/specific/ubuntu.fish
        case arch
            source $HOME/.config/fish/specific/arch.fish
    end
end


bind \cH backward-kill-word # Ctrl + Backspace
bind \e\[3\;5~ kill-word



if test -n "$WSL_INTEROP"
    source $HOME/.config/fish/specific/wsl.fish
end
