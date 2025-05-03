export SURFSHARK_ADAPTERS=(eth0 eth2)

for adapter in ${SURFSHARK_ADAPTERS[@]}; do
    ip a | rg $adapter &> /dev/null && sudo ip link set dev $adapter mtu 1350 &> /dev/null
done

command -v dbus-launch > /dev/null && export $(dbus-launch)
export GALLIUM_DRIVER=d3d12
export LIBVA_DRIVERS_PATH=/usr/lib/dri
export LIBVA_DRIVER_NAME=d3d12
export VDPAU_DRIVER=d3d12

eval "$(wsl2-ssh-agent)"

if [[ ! -e ~/.local/bin/code ]]; then
    ln -s "/mnt/c/Users/tim/AppData/Local/Programs/Microsoft VS Code/bin/code" ~/.local/bin/code
fi

alias explorer.exe="/mnt/c/windows/explorer.exe"
alias op="/mnt/c/Users/tim/AppData/Local/Microsoft/WinGet/Links/op.exe"
