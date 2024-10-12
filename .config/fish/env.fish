fish_add_path "$HOME/.cargo/bin"
fish_add_path "$HOME/.radicle/bin"
fish_add_path "$HOME/.local/bin"
fish_add_path "$HOME/go/bin"
fish_add_path /usr/local/cuda/bin
fish_add_path /opt/cuda/bin

set -x ZVM_INSTALL "$HOME/.zvm/self"
fish_add_path "$HOME/.zvm/bin"
fish_add_path "$ZVM_INSTALL"
fish_add_path "$HOME/3rd-party/depot_tools"

set -x VOLTA_HOME "$HOME/.volta"
fish_add_path "$VOLTA_HOME/bin"
set -x VOLTA_FEATURE_PNPM 1

set -x BUN_INSTALL "$HOME/.bun"
fish_add_path "$BUN_INSTALL/bin"

set -x PNPM_HOME "$HOME/.local/share/pnpm"
fish_add_path "$PNPM_HOME"

fish_add_path /usr/local/go/bin
fish_add_path /usr/bin/FlameGraph

set -x EDITOR code

set -x MODULAR_HOME "$HOME/.modular"
fish_add_path "$MODULAR_HOME/pkg/packages.modular.com_mojo/bin"
fish_add_path "$MODULAR_HOME/bin"
set -x MAX_PATH "$MODULAR_HOME/pkg/packages.modular.com_max"
fish_add_path "$MAX_PATH/bin"

fish_add_path "$HOME/.dotnet" "$HOME/.dotnet/tools"

set -x CC clang
set -x CXX clang++

fish_add_path "$HOME/.turso"
fish_add_path "$HOME/.cache/rebar3/bin"

set -x DENO_INSTALL "$HOME/.deno"
fish_add_path "$DENO_INSTALL/bin"

set -x JAVA_HOME /usr/lib/jvm/default
fish_add_path "$JAVA_HOME/bin"
fish_add_path "$HOME/.local/share/coursier/bin"

set -x LD_LIBRARY_PATH "/usr/lib/wsl/lib:/usr/local/lib:/usr/local/cuda/lib64:/usr/lib:/opt/cuda/lib:$LD_LIBRARY_PATH"
set -x LD mold
set -x LIBRARY_PATH "$LD_LIBRARY_PATH"

fish_add_path "$HOME/3rd-party/swift/usr/bin"

set -x VCPKG_ROOT "$HOME/vcpkg"
set -x VCPKG_DEFAULT_TRIPLET "x64-linux"

set -x WASMER_DIR "$HOME/.wasmer"

set -x WASMER_DIR "$HOME/.wasmer"
set -x WASMER_CACHE_DIR "$WASMER_DIR/cache"
fish_add_path "$WASMER_DIR/bin"

set -x GHIDRA_ROOT "/opt/ghidra"
set -x BAT_THEME "OneDark"

source "$HOME/.atuin/bin/env.fish"

fish_add_path "/opt/rocm/bin"
set -x HIP_PLATFORM 'nvidia'

set -x ANDROID_HOME "/opt/android-sdk"
set -x NDK_HOME "/opt/android-ndk"
set -x PAGER "moar"

