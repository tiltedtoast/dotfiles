## Install the required software

```shell
sudo apt update
sudo apt upgrade -y
sudo apt install -y unzip git zsh stow curl wget cmake imagemagick libssl-dev fzf

# Oh My Posh
curl -s https://ohmyposh.dev/install.sh | sudo bash -s

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
&& sudo apt update \
&& sudo apt install gh -y

# Python
sudo apt install software-properties-common
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt update
sudo apt install python3.12
curl -sSL https://bootstrap.pypa.io/get-pip.py | python3.12

# LLVM
sudo apt install lsb-release wget software-properties-common gnupg -y
sudo bash -c "$(wget -O - https://apt.llvm.org/llvm.sh)"
LLVM_VERSION=$(echo $(ls /usr/bin | /usr/bin/grep clang | /usr/bin/grep -oP '\d{2}') | tr ' ' '\n' | sort -n | tail -1)
sudo apt install clang-format-$LLVM_VERSION
sudo ln -sf /usr/bin/clang-$LLVM_VERSION /usr/bin/clang
sudo ln -sf /usr/bin/clangd-$LLVM_VERSION /usr/bin/clangd
sudo ln -sf /usr/bin/clang++-$LLVM_VERSION /usr/bin/clang++
sudo ln -sf /usr/bin/ld.lld-$LLVM_VERSION /usr/bin/ld.lld
sudo ln -sf /usr/bin/clang-format-$LLVM_VERSION /usr/bin/clang-format
export CC=clang
export CXX=clang++

# Mold Linker
mkdir -p $HOME/3rd-party
git clone https://github.com/rui314/mold.git $HOME/3rd-party/mold
mkdir $HOME/3rd-party/mold/build
cd $HOME/3rd-party/mold/build
git checkout v2.4.1
sudo ../install-build-deps.sh
cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_COMPILER=c++ ..
cmake --build . -j $(nproc)
sudo cmake --build . --target install

# Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
. $HOME/.cargo/env
cargo install cargo-binstall
cargo binstall -y eza
cargo binstall -y ripgrep --features 'pcre2'
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
