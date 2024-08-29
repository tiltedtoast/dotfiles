## Install the required software

```shell
sudo apt update
sudo apt upgrade -y
sudo apt install nala
sudo nala install -y git-delta unzip git zsh stow curl wget cmake imagemagick libssl-dev fzf

# Atuin
curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh

# Oh My Posh
curl -s https://ohmyposh.dev/install.sh | sudo bash -s -- -d ~/.local/bin

# Zoxide
curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash

# Volta
curl https://get.volta.sh | bash
$HOME/.volta/bin/volta install node@latest
$HOME/.volta/bin/volta install pnpm
$HOME/.volta/bin/volta install pm2

# Bun
curl -fsSL https://bun.sh/install | bash

# GitHub CLI
sudo mkdir -p -m 755 /etc/apt/keyrings && wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
&& sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
&& sudo nala update -y \
&& sudo nala install gh -y

# Python
curl -LsSf https://astral.sh/uv/install.sh | sh
sudo nala install -y software-properties-common
echo -ne '\n'| sudo add-apt-repository ppa:deadsnakes/ppa
sudo nala update
sudo nala install -y python3.12 python3.12-dev
curl -sSL https://bootstrap.pypa.io/get-pip.py | python3.12

# LLVM
sudo nala install lsb-release wget software-properties-common gnupg -y
echo -ne '\n' | sudo bash -c "$(wget -O - https://apt.llvm.org/llvm.sh)"
LLVM_VERSION=$(echo $(ls /usr/bin | /usr/bin/grep clang | /usr/bin/grep -oP '\d{2}') | tr ' ' '\n' | sort -n | tail -1)
sudo nala install clang-format-$LLVM_VERSION
sudo ln -sf /usr/bin/clang-$LLVM_VERSION /usr/bin/clang
sudo ln -sf /usr/bin/clangd-$LLVM_VERSION /usr/bin/clangd
sudo ln -sf /usr/bin/clang++-$LLVM_VERSION /usr/bin/clang++
sudo ln -sf /usr/bin/ld.lld-$LLVM_VERSION /usr/bin/ld.lld
sudo ln -sf /usr/bin/clang-format-$LLVM_VERSION /usr/bin/clang-format

# Mold Linker
mkdir -p $HOME/3rd-party
git clone --branch stable https://github.com/rui314/mold.git $HOME/3rd-party/mold
cd $HOME/3rd-party/mold
sudo ./install-build-deps.sh
cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_COMPILER=c++ -B build
cmake --build build -j$(nproc)
sudo cmake --build build --target install

# Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
. $HOME/.cargo/env
rustup toolchain install nightly
cargo install cargo-binstall
cargo binstall -y eza
cargo binstall -y ripgrep
cargo binstall -y bat
cargo binstall -y fd-find
cargo binstall -y sd

bat cache --build
```

## Set up the dotfiles

### DON'T FORGET TO SET UP SSH KEYS FIRST

```shell
echo '
[core]
    sshCommand = ssh -i "$HOME/.ssh/git" -o IdentitiesOnly=yes
' > $HOME/.gitconfig

sudo chmod 700 $HOME/.ssh
sudo chmod 600 $HOME/.ssh/git
sudo chmod 644 $HOME/.ssh/git.pub

git clone --recurse-submodules git@github.com:TiltedToast/dotfiles.git $HOME/dotfiles
cd $HOME/dotfiles

rm -rf $HOME/.gitconfig $HOME/.bashrc $Home/.zshrc
```

#### Then, apply the dotfiles

```shell
stow .
```

### Last but not least, set the default shell to zsh and restart the terminal

```shell
chsh -s $(which zsh)
```
