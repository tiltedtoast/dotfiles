fish_add_path "$HOME/.local/bin"
fish_add_path "$HOME/bin"
fish_add_path /usr/local/bin
fish_add_path "$HOME/go/bin"
fish_add_path /usr/local/cuda/bin
fish_add_path "$HOME/3rd-party/depot_tools"
fish_add_path /usr/local/go/bin /usr/bin/FlameGraph
fish_add_path "$VOLTA_HOME/bin"
fish_add_path "$HOME/.zvm/bin"
fish_add_path "$ZVM_INSTALL"
fish_add_path "$BUN_INSTALL/bin"
fish_add_path "$PNPM_HOME"
fish_add_path "$MODULAR_HOME/pkg/packages.modular.com_mojo/bin"
fish_add_path "$HOME/.dotnet" "$HOME/.dotnet/tools"
fish_add_path "$HOME/.turso"
fish_add_path "$HOME/.cache/rebar3/bin"
fish_add_path "$DENO_INSTALL/bin"
fish_add_path "$JAVA_HOME/bin"
fish_add_path "$HOME/.local/share/coursier/bin"
fish_add_path "$HOME/.cargo/bin"
fish_add_path "$HOME/3rd-party/swift/usr/bin"

set fish_greeting ""

set -x VOLTA_HOME "$HOME/.volta"
set -x VOLTA_FEATURE_PNPM 1
set -x ZVM_INSTALL "$HOME/.zvm/self"
set -x BUN_INSTALL "$HOME/.bun"
set -x PNPM_HOME "$HOME/.local/share/pnpm"
set -x EDITOR code
set -x CC clang
set -x MODULAR_HOME "$HOME/.modular"
set -x WASMER_DIR "$HOME/.wasmer"
set -x CXX clang++
set -x DENO_INSTALL "$HOME/.deno"
set -x JAVA_HOME "$HOME/3rd-party/graalvm"
set -x LD_LIBRARY_PATH "/usr/local/lib:/usr/local/cuda/lib64:$LD_LIBRARY_PATH"
set -x LD mold
