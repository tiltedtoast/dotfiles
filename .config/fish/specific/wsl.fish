set -x SURFSHARK_ADAPTERS eth0 eth2


for adapter in $SURFSHARK_ADAPTERS
    if ip a | rg $adapter &>/dev/null
        sudo ip link set dev $adapter mtu 1350 &>/dev/null
    end
end


# wrap_env_command (dbus-launch)
# set -x (dbus-launch)
eval (opam env)

pgrep -f wait-forever.sh >/dev/null || nohup ./wait-forever.sh &>/dev/null


if not test -e /usr/local/bin/explorer.exe
    sudo ln -s /mnt/c/windows/explorer.exe /usr/local/bin/explorer.exe
end

if not test -e /usr/local/bin/code
    sudo ln -s "/mnt/c/Users/tim/AppData/Local/Programs/Microsoft VS Code/bin/code" /usr/local/bin/code
end
