export SURFSHARK_ADAPTERS=(eth0 eth2)

for adapter in ${SURFSHARK_ADAPTERS[@]}; do
    ip a | rg $adapter &> /dev/null && sudo ip link set dev $adapter mtu 1350 &> /dev/null
done

export $(dbus-launch)
export GALLIUM_DRIVER=d3d12
export LIBVA_DRIVERS_PATH=/usr/lib/dri
export LIBVA_DRIVER_NAME=d3d12
export VDPAU_DRIVER=d3d12

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

alias explorer.exe="/mnt/c/windows/explorer.exe"
alias op="/mnt/c/Users/tim/AppData/Local/Microsoft/WinGet/Links/op.exe"
