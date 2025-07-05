alias update="sudo pacman -Syu"
alias yayupdate="yay -Syu"

function listfiles
    pacman -Ql $argv[1] | awk '{print $2}'
end

alias VK_DRIVER_FILES="/usr/share/vulkan/icd.d/dzn_icd.x86_64.json"

function aur-clone
    git clone ssh://aur@aur.archlinux.org/$argv[1].git
end